#if canImport(SwiftUI) && canImport(SpriteKit)
import AVFoundation
import PantryGame

/// Plays the placeholder cues through AVAudioEngine: a small pool of player nodes so
/// a sizzle can still be ringing when the next ingredient lands (brief: layered playback).
///
/// The audio session is `.ambient` (PD-016): the game obeys the silent switch and plays
/// over the player's own music or podcast instead of stopping it.
@MainActor
final class SoundPlayer {
    var isMuted: Bool

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [SoundCue: AVAudioPCMBuffer] = [:]
    private var nextPlayer = 0
    private var prepared = false

    init(isMuted: Bool = false) {
        self.isMuted = isMuted
    }

    /// Builds the buffers and wires the engine. Safe to call more than once. Does nothing
    /// while muted, so a muted game never touches the audio hardware.
    func prepare() {
        guard !prepared, !isMuted else { return }
        prepared = true

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        // No output device (a headless simulator, say): stay silent rather than let
        // AVAudioEngine raise on an invalid format. The visual twins carry the round.
        let output = engine.outputNode.outputFormat(forBus: 0)
        guard output.channelCount > 0, output.sampleRate > 0,
              let format = AVAudioFormat(standardFormatWithSampleRate: PlaceholderSynth.sampleRate, channels: 1)
        else { return }

        for cue in SoundCue.allCases {
            let samples = PlaceholderSynth.samples(for: cue)
            guard !samples.isEmpty,
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
                  let channels = buffer.floatChannelData
            else { continue }
            buffer.frameLength = AVAudioFrameCount(samples.count)
            for (index, sample) in samples.enumerated() {
                channels[0][index] = sample
            }
            buffers[cue] = buffer
        }

        for _ in 0..<4 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
    }

    func play(_ cue: SoundCue) {
        guard !isMuted else { return }
        prepare()
        guard let buffer = buffers[cue], !players.isEmpty else { return }
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                return
            }
        }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
    }
}
#endif
