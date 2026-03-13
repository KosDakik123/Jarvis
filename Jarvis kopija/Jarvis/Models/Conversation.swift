//
//  Conversation.swift
//  Jarvis
//

import Foundation

/// In-memory conversation with messages (SwiftData version can be added for persistence).
struct Conversation: Sendable {
    var messages: [Message]
    var createdAt: Date
    var updatedAt: Date

    init(messages: [Message] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    mutating func append(_ message: Message) {
        messages.append(message)
        updatedAt = Date()
    }
}
