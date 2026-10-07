import Foundation

/// Placeholder sounds, synthesised in code (PD-014). No audio files ship until
/// Moe's recordings replace these (PB-011), so there is nothing to license and
/// nothing binary in the repository. Deterministic: the same cue always yields
/// the same samples.
public enum PlaceholderSynth {
    public static let sampleRate = 44_100.0

    /// Mono samples in -1...1 at `sampleRate`.
    public static func samples(for cue: SoundCue) -> [Float] {
        var samples: [Float]
        switch cue {
        case .sizzle: samples = sizzle()
        case .boil: samples = boil()
        case .splash: samples = splash()
        case .clatter: samples = clatter()
        case .flame: samples = flame()
        }
        normalize(&samples, peak: 0.6)
        return samples
    }

    private static func count(_ seconds: Double) -> Int {
        Int(seconds * sampleRate)
    }

    /// Bright hiss with crackle: high-passed noise, quick attack, slow decay.
    private static func sizzle() -> [Float] {
        var rng = SeededGenerator(seed: 0x51_22_1E)
        let n = count(0.75)
        var out = [Float](repeating: 0, count: n)
        var previous: Float = 0
        var crackle: Float = 1
        for i in 0..<n {
            let t = Double(i) / sampleRate
            let noise = rng.signedUnit()
            let highPassed = noise - previous
            previous = noise
            if i % 441 == 0 { crackle = 0.55 + 0.45 * abs(rng.signedUnit()) }
            let attack = min(1, t / 0.01)
            let decay = exp(-t * 4.5)
            out[i] = highPassed * crackle * Float(attack * decay)
        }
        return out
    }

    /// A handful of rising "blub" tones at scattered offsets.
    private static func boil() -> [Float] {
        var rng = SeededGenerator(seed: 0xB0_11)
        let n = count(0.85)
        var out = [Float](repeating: 0, count: n)
        let blubLength = count(0.07)
        for blub in 0..<7 {
            let start = Int(Double(blub) * 0.105 * sampleRate + rng.unit() * 0.03 * sampleRate)
            let base = 260 + rng.unit() * 220
            var phase = 0.0
            for j in 0..<blubLength where start + j < n {
                let x = Double(j) / Double(blubLength)
                let frequency = base * (1 + 0.9 * x)
                phase += 2 * Double.pi * frequency / sampleRate
                let envelope = sin(Double.pi * x)
                out[start + j] += Float(sin(phase) * envelope)
            }
        }
        return out
    }

    /// A soft wet thump: low-passed noise that opens and closes fast.
    private static func splash() -> [Float] {
        var rng = SeededGenerator(seed: 0x5F_1A_54)
        let n = count(0.45)
        var out = [Float](repeating: 0, count: n)
        var low: Float = 0
        for i in 0..<n {
            let t = Double(i) / sampleRate
            low += 0.18 * (rng.signedUnit() - low)
            let attack = min(1, t / 0.006)
            let decay = exp(-t * 11)
            out[i] = low * Float(attack * decay)
        }
        return out
    }

    /// Four short, bright, damped pings: dry goods on metal.
    private static func clatter() -> [Float] {
        var rng = SeededGenerator(seed: 0xC1_A7)
        let n = count(0.42)
        var out = [Float](repeating: 0, count: n)
        for offset in [0.0, 0.07, 0.13, 0.21] {
            let start = count(offset)
            let frequency = 1700 + rng.unit() * 1500
            let gain = Float(0.6 + rng.unit() * 0.4)
            for j in 0..<count(0.09) where start + j < n {
                let t = Double(j) / sampleRate
                out[start + j] += gain * Float(sin(2 * Double.pi * frequency * t) * exp(-t * 60))
            }
        }
        return out
    }

    /// A click, then a low swell: the burner catching.
    private static func flame() -> [Float] {
        var rng = SeededGenerator(seed: 0xF1_A3)
        let n = count(0.55)
        var out = [Float](repeating: 0, count: n)
        var low: Float = 0
        for i in 0..<n {
            let t = Double(i) / sampleRate
            low += 0.04 * (rng.signedUnit() - low)
            let click = t < 0.004 ? Float(sin(2 * Double.pi * 2400 * t)) : 0
            let swell = sin(Double.pi * min(1, t / 0.5))
            out[i] = click * 0.8 + low * Float(swell) * 3
        }
        return out
    }

    private static func normalize(_ samples: inout [Float], peak: Float) {
        let loudest = samples.reduce(Float(0)) { max($0, abs($1)) }
        guard loudest > 0 else { return }
        let gain = peak / loudest
        for i in samples.indices { samples[i] *= gain }
    }
}
