//
//  AudioSessionManager.swift
//  Jarvis
//

import AVFoundation

/// Manages AVAudioSession for playAndRecord, speaker default, interruptions.
final class AudioSessionManager: @unchecked Sendable {

    static let shared = AudioSessionManager()

    private let session = AVAudioSession.sharedInstance()

    private init() {}

    func configureForVoice() throws {
        // Measurement mode is recommended for speech recognition and avoids odd 0 Hz formats.
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .duckOthers])
        try session.setPreferredSampleRate(44_100)
        try session.setActive(true)
    }

    func setActive(_ active: Bool) throws {
        try session.setActive(active, options: .notifyOthersOnDeactivation)
    }

    func handleInterruption(type: AVAudioSession.InterruptionType) {
        if type == .ended {
            try? session.setActive(true)
        }
    }
}
