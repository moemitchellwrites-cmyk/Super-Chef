#if canImport(SwiftUI) && canImport(SpriteKit)
import SwiftUI
import PantryScoring

/// The score for a served attempt. A stand-in: the judge's line (PB-003) and the
/// card (PB-004) replace the raw breakdown below the number.
struct ScoreSheet: View {
    let dish: DishProfile
    let breakdown: ScoreBreakdown
    let onKeepCooking: () -> Void
    let onStartOver: () -> Void

    private struct Part: Identifiable {
        let name: String
        let earned: Double
        let possible: Double
        var id: String { name }
    }

    private var parts: [Part] {
        [
            Part(name: "Ingredients", earned: breakdown.coverage, possible: ScoreWeights.coverage),
            Part(name: "Ratios", earned: breakdown.ratioFit, possible: ScoreWeights.ratioFit),
            Part(name: "Flavour", earned: breakdown.signature, possible: ScoreWeights.signature),
            Part(name: "Technique", earned: breakdown.technique, possible: ScoreWeights.technique),
        ]
    }

    private var missCodes: [String] {
        Array(Set(breakdown.misses.map(\.code))).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(dish.name)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("\(breakdown.total)")
                    .font(.system(size: 76, weight: .heavy, design: .rounded))
                    .accessibilityIdentifier("score-total")
                    .accessibilityLabel("\(breakdown.total) out of 100")
                VStack(spacing: 8) {
                    ForEach(parts) { part in
                        HStack(spacing: 10) {
                            Text(part.name)
                                .font(.subheadline)
                                .frame(width: 92, alignment: .leading)
                            ProgressView(value: min(max(part.earned, 0), part.possible), total: part.possible)
                                .tint(.orange)
                            Text("\(part.earned.formatted(.number.precision(.fractionLength(0...1)))) / \(Int(part.possible))")
                                .font(.subheadline.monospacedDigit())
                                .frame(width: 74, alignment: .trailing)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                if !missCodes.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("What cost points (raw, until the judge can talk)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(missCodes, id: \.self) { code in
                            Text(code)
                                .font(.caption.monospaced())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 10) {
                    Button("Keep cooking", action: onKeepCooking)
                        .buttonStyle(.bordered)
                    Button("Start over", action: onStartOver)
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                }
                .controlSize(.large)
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
    }
}
#endif
