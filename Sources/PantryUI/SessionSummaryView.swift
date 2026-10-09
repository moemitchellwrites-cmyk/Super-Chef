#if canImport(SwiftUI) && canImport(SpriteKit)
import SwiftUI
import PantryGame
import PantryScoring

/// The end of a five-round session (PB-005): how it went, each dish, the best one and one to revisit.
struct SessionSummaryView: View {
    let summary: SessionSummary
    let library: ContentLibrary
    let finishedBefore: Int
    let onNewSession: () -> Void

    private struct Row: Identifiable {
        let id: Int
        let name: String
        let score: String
        let tag: String?
    }

    private func name(_ dishId: String) -> String {
        library.dish(id: dishId)?.name ?? dishId
    }

    private var rows: [Row] {
        summary.records.enumerated().map { index, record in
            var tag: String?
            if record == summary.best { tag = "Best" }
            if record == summary.revisit { tag = "Worth another go" }
            let score = summary.mode == .kitchen ? "\(record.points)" : "\(record.points) of \(record.outOf)"
            return Row(id: index, name: name(record.dishId), score: score, tag: tag)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("\(summary.mode.title) session \(finishedBefore + 1)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(summary.headlineNumber)
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityIdentifier("session-total")
                Text(summary.headlineCaption)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(summary.line)
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("session-line")
                VStack(spacing: 8) {
                    ForEach(rows) { row in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.name)
                                    .font(.body.weight(.medium))
                                if let tag = row.tag {
                                    Text(tag)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.orange)
                                }
                            }
                            Spacer(minLength: 8)
                            Text(row.score)
                                .font(.body.monospacedDigit().weight(.semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.gray.opacity(0.12)))
                        .accessibilityElement(children: .combine)
                    }
                }
                if let revisit = summary.revisit, let card = library.dish(id: revisit.dishId).flatMap({ library.card(for: $0) }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("For \(name(revisit.dishId).prefix(1).lowercased() + name(revisit.dishId).dropFirst()) next time")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        CardView(card: card)
                    }
                }
                Button(action: onNewSession) {
                    Text("New session")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
                .accessibilityIdentifier("new-session")
            }
            .padding(20)
        }
        .interactiveDismissDisabled()
    }
}
#endif
