//
//  LLMConfiguration.swift
//  Jarvis
//

import Foundation

/// Configuration for LLM inference (context size, sampling, etc.).
struct LLMConfiguration: Sendable {
    var contextSize: Int
    var temperature: Float
    var topP: Float
    var topK: Int
    var repeatPenalty: Float
    var maxTokens: Int

    static let `default` = LLMConfiguration(
        // Smaller context + shorter replies for better on-device performance.
        contextSize: 2048,
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        repeatPenalty: 1.1,
        maxTokens: 1024
    )
}
