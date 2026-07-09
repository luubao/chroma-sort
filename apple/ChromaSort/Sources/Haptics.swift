import CoreHaptics
import UIKit

/// The game calls `navigator.vibrate(...)`, which is a permanent no-op in
/// WKWebView on Apple platforms. The web layer forwards those calls here
/// instead, and we replay the pattern on the Taptic Engine.
///
/// A Vibration API pattern is an alternating list of milliseconds:
/// `[buzz, pause, buzz, pause, ...]`, starting with a buzz. A bare number is a
/// single buzz.
final class Haptics {
    private var engine: CHHapticEngine?
    private let supportsHaptics: Bool

    init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard supportsHaptics else { return }
        engine = try? CHHapticEngine()
        // The engine is stopped on backgrounding and after audio interruptions;
        // restart lazily rather than holding it running.
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        engine?.stoppedHandler = { _ in }
        try? engine?.start()
    }

    func play(pattern milliseconds: [Double]) {
        let buzzes = strideBuzzes(milliseconds)
        guard !buzzes.isEmpty else { return }

        guard supportsHaptics, let engine else {
            // iPads, Macs, and the Simulator have no Taptic Engine. Fall back to
            // the feedback generator, which is a no-op there but correct on any
            // device that gains support.
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        let events = buzzes.map { buzz -> CHHapticEvent in
            // Short taps read as crisp; longer ones as a heavier thud.
            let intensity = Float(min(1.0, 0.35 + buzz.duration / 60.0))
            let sharpness = Float(max(0.3, 1.0 - buzz.duration / 80.0))
            return CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: intensity),
                    .init(parameterID: .hapticSharpness, value: sharpness),
                ],
                relativeTime: buzz.start / 1000.0
            )
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private struct Buzz {
        let start: Double     // ms from the beginning of the pattern
        let duration: Double  // ms
    }

    /// Even indices are buzzes, odd indices are the silent gaps between them.
    private func strideBuzzes(_ milliseconds: [Double]) -> [Buzz] {
        var buzzes: [Buzz] = []
        var cursor: Double = 0
        for (index, value) in milliseconds.enumerated() where value > 0 {
            if index.isMultiple(of: 2) {
                buzzes.append(Buzz(start: cursor, duration: value))
            }
            cursor += value
        }
        return buzzes
    }
}
