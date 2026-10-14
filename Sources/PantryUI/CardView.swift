#if canImport(SwiftUI) && canImport(SpriteKit)
import SwiftUI
import PantryScoring

/// The one card a round ends on (PB-004): a title, the lesson, one rule, one thing to try tonight.
struct CardView: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CARD")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(PanelInk.soft)
                .accessibilityHidden(true)
            Text(card.title)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(PanelInk.chili)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("card-title")
            Text(card.body)
                .font(.subheadline)
                .foregroundStyle(PanelInk.ink)
            Text("Rule: \(card.rule)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PanelInk.ink)
            Text("\(Text("Try this tonight:").bold()) \(card.tryTonight)")
                .font(.footnote)
                .foregroundStyle(PanelInk.soft)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(PanelInk.panel))
    }
}
#endif
