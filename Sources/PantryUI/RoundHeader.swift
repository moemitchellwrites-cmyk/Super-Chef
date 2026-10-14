#if canImport(SwiftUI) && canImport(SpriteKit)
import SwiftUI
import PantryGame

/// The row above every round (PD-031): the mode switch, start over, sound.
struct RoundHeader: View {
    @Binding var mode: GameMode
    let canStartOver: Bool
    let isMuted: Bool
    let onStartOver: () -> Void
    let onToggleMute: () -> Void

    @State private var showingTip = false

    private static let startOverTip = "Start over: clears the round"

    var body: some View {
        HStack(spacing: 8) {
            modeSwitch
            Spacer(minLength: 0)
            startOver
            Button(action: onToggleMute) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.gray.opacity(0.16)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isMuted ? "Turn sound on" : "Turn sound off")
            .accessibilityIdentifier("mute")
        }
    }

    private var modeSwitch: some View {
        HStack(spacing: 4) {
            ForEach(GameMode.allCases, id: \.self) { choice in
                modeButton(choice)
            }
        }
        .padding(4)
        .frame(width: 184, height: 44)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.gray.opacity(0.16)))
    }

    private func modeButton(_ choice: GameMode) -> some View {
        let chosen = mode == choice
        return Button {
            mode = choice
        } label: {
            Text(choice.title)
                .font(.system(.subheadline, design: .rounded).weight(chosen ? .semibold : .medium))
                .foregroundStyle(chosen ? Color.primary : Color.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(chosen ? Color.gray.opacity(0.28) : Color.clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(chosen ? .isSelected : [])
        .accessibilityIdentifier("mode-\(choice.rawValue)")
    }

    /// An icon, not a worded button (Moe's call). Its name is there on demand: hover with a pointer,
    /// press and hold on touch, and always for VoiceOver.
    private var startOver: some View {
        Image(systemName: "arrow.counterclockwise")
            .frame(width: 44, height: 44)
            .background(Circle().fill(Color.gray.opacity(0.16)))
            .opacity(canStartOver ? 1 : 0.4)
            .contentShape(Circle())
            .onTapGesture {
                if canStartOver { onStartOver() }
            }
            .onLongPressGesture(minimumDuration: 0.4) {
                showingTip = true
            }
            .help(Self.startOverTip)
            .popover(isPresented: $showingTip) {
                Text(Self.startOverTip)
                    .font(.footnote)
                    .padding(12)
                    .presentationCompactAdaptation(.popover)
            }
            .accessibilityElement()
            .accessibilityLabel("Start over")
            .accessibilityHint("Clears the round")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                if canStartOver { onStartOver() }
            }
            .accessibilityIdentifier("start-over")
    }
}
#endif
