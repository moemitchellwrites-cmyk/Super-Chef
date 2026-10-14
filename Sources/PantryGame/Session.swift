import Foundation
import PantryScoring

/// How one round of a session came out. Kitchen rounds are out of 100; Pantry rounds are out of the
/// dish's number of essentials.
public struct RoundRecord: Codable, Equatable, Sendable {
    public var dishId: String
    public var points: Int
    public var outOf: Int

    public init(dishId: String, points: Int, outOf: Int) {
        self.dishId = dishId
        self.points = points
        self.outOf = outOf
    }

    /// 0...1, so rounds with different ceilings can be compared.
    public var fraction: Double {
        outOf > 0 ? Double(points) / Double(outOf) : 0
    }
}

/// A session (brief: "3 to 5 rounds, then a summary"): five different dishes in one mode, dealt up
/// front. No timer, no lives, nothing lost by stopping: a session waits where it was left.
public struct Session: Codable, Equatable, Sendable {
    public static let length = 5

    public let mode: GameMode
    public let dishIds: [String]
    public private(set) var records: [RoundRecord] = []
    /// The first serve of the round in play. It is the one that counts: after it the player has seen
    /// the verdict, so a second serve of the same dish is practice, not a result.
    public private(set) var served: RoundRecord?

    /// Deals a session from the dishes on offer.
    /// - Parameters:
    ///   - avoiding: dishes from the session before, kept out while there are enough others.
    ///   - first: a dish to open on (tests, demos). Ignored when it isn't on offer.
    public init(mode: GameMode, dishes: [DishProfile], avoiding: Set<String> = [], first: String? = nil, seed: UInt64) {
        self.mode = mode
        var generator = SeededGenerator(seed: seed)
        let shuffled = dishes.map(\.id).shuffled(using: &generator)
        var dealt = shuffled.filter { !avoiding.contains($0) } + shuffled.filter { avoiding.contains($0) }
        if let first, let index = dealt.firstIndex(of: first) {
            dealt.remove(at: index)
            dealt.insert(first, at: 0)
        }
        dishIds = Array(dealt.prefix(Session.length))
    }

    public var isComplete: Bool {
        records.count >= dishIds.count
    }

    /// The dish to cook now. Nil once the session is complete.
    public var currentDishId: String? {
        isComplete ? nil : dishIds[records.count]
    }

    /// 1-based, and it stays on the last round once the session is complete.
    public var roundNumber: Int {
        min(records.count + 1, dishIds.count)
    }

    /// "2 of 5"
    public var progressLabel: String {
        "\(roundNumber) of \(dishIds.count)"
    }

    public var isLastRound: Bool {
        records.count == dishIds.count - 1
    }

    /// Notes a serve of the current dish. Only the first one in a round is kept.
    /// Returns true when this serve is the one that counts.
    @discardableResult
    public mutating func serve(points: Int, outOf: Int) -> Bool {
        guard served == nil, let dishId = currentDishId else { return false }
        served = RoundRecord(dishId: dishId, points: points, outOf: outOf)
        return true
    }

    /// Settles the round with its first serve and moves to the next dish.
    /// Returns false when nothing has been served yet or the session is already complete.
    @discardableResult
    public mutating func advance() -> Bool {
        guard !isComplete, let served else { return false }
        records.append(served)
        self.served = nil
        return true
    }

    /// Serves and settles in one step.
    @discardableResult
    public mutating func record(points: Int, outOf: Int) -> Bool {
        guard serve(points: points, outOf: outOf) else { return false }
        return advance()
    }

    public var summary: SessionSummary {
        SessionSummary(mode: mode, records: records)
    }
}

/// What the summary screen says about a finished session. Coach, don't shame: it names the best
/// round and one to revisit, and never ranks the player.
public struct SessionSummary: Equatable, Sendable {
    public let mode: GameMode
    public let records: [RoundRecord]

    public var points: Int { records.reduce(0) { $0 + $1.points } }
    public var outOf: Int { records.reduce(0) { $0 + $1.outOf } }

    /// 0...1 across the session, each round weighted equally.
    public var fraction: Double {
        records.isEmpty ? 0 : records.reduce(0) { $0 + $1.fraction } / Double(records.count)
    }

    /// Kitchen: the average score, "78". Pantry: essentials found of all there were, "24 of 31".
    public var headlineNumber: String {
        switch mode {
        case .kitchen: return records.isEmpty ? "0" : String(Int((Double(points) / Double(records.count)).rounded()))
        case .pantry: return "\(points) of \(outOf)"
        }
    }

    public var headlineCaption: String {
        mode == .kitchen ? "average across \(records.count) dishes" : "essentials found across \(records.count) dishes"
    }

    /// One plain sentence. The bands are wide on purpose: this is a pat on the back, not a grade.
    public var line: String {
        switch fraction {
        case 0.85...: return "A strong service."
        case 0.65..<0.85: return "Solid cooking, with a dish or two to tighten."
        default: return "A learning service. The cards are the shortcut."
        }
    }

    /// The round that went best. The first one wins a tie.
    public var best: RoundRecord? {
        records.enumerated().max { ($0.element.fraction, -$0.offset) < ($1.element.fraction, -$1.offset) }?.element
    }

    /// The round most worth another go: the lowest, unless everything was perfect or there was only one round.
    public var revisit: RoundRecord? {
        guard records.count > 1,
              let lowest = records.enumerated().min(by: { ($0.element.fraction, $0.offset) < ($1.element.fraction, $1.offset) })?.element,
              lowest.fraction < 1, lowest != best else { return nil }
        return lowest
    }
}

/// Everything the game remembers between launches (brief: "local progress"). One small file on the
/// phone; nothing leaves it.
public struct GameProgress: Codable, Equatable, Sendable {
    public struct Finished: Codable, Equatable, Sendable {
        public var session: Session
        public var finishedAt: Date
    }

    public var schemaVersion = 1
    public private(set) var finished: [Finished] = []
    /// The session in play in each mode, by `GameMode.rawValue`.
    public private(set) var current: [String: Session] = [:]

    public init() {}

    public func session(for mode: GameMode) -> Session? {
        current[mode.rawValue]
    }

    public mutating func setSession(_ session: Session) {
        current[session.mode.rawValue] = session
    }

    /// Files a completed session and clears it from play. Returns false for one that isn't complete.
    @discardableResult
    public mutating func finish(_ session: Session, at date: Date) -> Bool {
        guard session.isComplete else { return false }
        finished.append(Finished(session: session, finishedAt: date))
        if current[session.mode.rawValue] == session {
            current[session.mode.rawValue] = nil
        }
        return true
    }

    public func finishedCount(in mode: GameMode) -> Int {
        finished.filter { $0.session.mode == mode }.count
    }

    /// The dishes of the last finished session in a mode, so the next deal can bring different ones.
    public func lastDishIds(in mode: GameMode) -> Set<String> {
        Set(finished.last { $0.session.mode == mode }?.session.dishIds ?? [])
    }

    /// The best this dish has gone in a mode, across finished sessions.
    public func best(dishId: String, in mode: GameMode) -> RoundRecord? {
        finished.filter { $0.session.mode == mode }
            .flatMap(\.session.records)
            .filter { $0.dishId == dishId }
            .max { $0.fraction < $1.fraction }
    }
}

/// reads and writes `GameProgress` as one JSON file. A missing or unreadable file is an empty start,
/// never an error the player sees.
public struct ProgressFile: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func load() -> GameProgress {
        guard let data = try? Data(contentsOf: url) else { return GameProgress() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(GameProgress.self, from: data)) ?? GameProgress()
    }

    public func save(_ progress: GameProgress) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(progress).write(to: url, options: .atomic)
    }
}
