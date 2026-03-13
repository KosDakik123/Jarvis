//
//  AssistantSettings.swift
//  Jarvis
//

import Foundation

/// User preferences for the assistant (voice, speed, model, toggles).
struct AssistantSettings: Sendable {
    var selectedModelIdentifier: String
    var voiceIdentifier: String
    var speechRate: Float
    var temperature: Float
    var maxTokens: Int
    var autoListenAfterResponse: Bool
    var showText: Bool
    var wakeWordEnabled: Bool
    /// Siri-like UX: press-and-hold to talk (instead of tap-to-toggle).
    var siriStyleHoldToTalk: Bool
    /// Enables the camera button and workspace attachment flow.
    var cameraEnabled: Bool

    static let `default` = AssistantSettings(
        // Optimized for Phi-3 / Gemma text models by default.
        selectedModelIdentifier: "phi-3-mini-instruct",
        voiceIdentifier: "com.apple.voice.premium.en-US.Samantha",
        speechRate: 0.5,
        temperature: 0.7,
        maxTokens: 512,
        autoListenAfterResponse: false,
        showText: true,
        wakeWordEnabled: true,
        siriStyleHoldToTalk: true,
        cameraEnabled: true
    )
}
