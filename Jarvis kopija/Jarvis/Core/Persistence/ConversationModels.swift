//
//  ConversationModels.swift
//  Jarvis
//
//
import Foundation
import SwiftData

@Model
final class ConversationEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var messages: [MessageEntity]

    init(title: String = "New chat") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
    }
}

@Model
final class MessageEntity {
    var role: String
    var content: String
    var createdAt: Date

    init(role: String, content: String) {
        self.role = role
        self.content = content
        self.createdAt = Date()
    }
}

