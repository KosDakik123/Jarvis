//
//  ConversationManagerTests.swift
//  JarvisTests
//

import Testing
@testable import Jarvis

struct ConversationManagerTests {

    @Test func appendAddsMessage() {
        let man = ConversationManager()
        man.append(Message(role: .user, content: "a"))
        #expect(man.conversation.messages.count == 1)
        #expect(man.conversation.messages[0].content == "a")
    }

    @Test func clearEmptiesConversation() {
        let man = ConversationManager()
        man.append(Message(role: .user, content: "x"))
        man.clear()
        #expect(man.conversation.messages.isEmpty)
    }

    @Test func trimmedMessagesEmptyWhenNoMessages() {
        let man = ConversationManager()
        #expect(man.trimmedMessages().isEmpty)
    }
}
