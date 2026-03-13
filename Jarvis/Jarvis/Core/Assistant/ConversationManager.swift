//
//  ConversationManager.swift
//  Jarvis
//

import Foundation

/// Manages conversation history and context window trimming.
final class ConversationManager: @unchecked Sendable {

    private let maxContextTokens: Int
    private(set) var conversation: Conversation

    init(maxContextTokens: Int = 4096, conversation: Conversation = Conversation()) {
        self.maxContextTokens = maxContextTokens
        self.conversation = conversation
    }

    func append(_ message: Message) {
        conversation.append(message)
    }

    /// Trim older messages so prompt fits in context, keeping system + recent turns.
    func trimmedMessages(systemPromptTokensEstimate: Int = 256) -> [Message] {
        let budget = maxContextTokens - systemPromptTokensEstimate
        let messages = conversation.messages.filter { $0.role != .system }
        if messages.isEmpty { return [] }
        // Simple strategy: keep last N messages by rough token count (≈4 chars/token).
        var kept: [Message] = []
        var used = 0
        for msg in messages.reversed() {
            let approx = msg.content.count / 4
            if used + approx > budget { break }
            kept.insert(msg, at: 0)
            used += approx
        }
        return kept
    }

    func clear() {
        conversation = Conversation()
    }
}
