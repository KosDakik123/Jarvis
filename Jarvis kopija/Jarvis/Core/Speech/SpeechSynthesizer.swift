//
//  SpeechSynthesizer.swift
//  Jarvis
//

import AVFoundation

/// TTS using AVSpeechSynthesizer; supports interruption and rate/pitch.
final class SpeechSynthesizer: NSObject, @unchecked Sendable {

    private let synthesizer = AVSpeechSynthesizer()

    var onFinish: (@Sendable () -> Void)?
    var onError: (@Sendable (Error) -> Void)?

    var voiceIdentifier: String = "com.apple.voice.premium.en-US.Samantha"
    var rate: Float = 0.5
    var pitchMultiplier: Float = 1.0

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        if let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * (0.5 + rate)
        utterance.pitchMultiplier = pitchMultiplier
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    var isSpeaking: Bool { synthesizer.isSpeaking }
}

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish?()
    }
}
