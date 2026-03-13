//
//  MessageTests.swift
//  JarvisTests
//

import Testing
@testable import Jarvis

struct MessageTests {

    @Test func messageRoles() {
        let user = Message(role: .user, content: "x")
        let assistant = Message(role: .assistant, content: "y")
        #expect(user.role == .user)
        #expect(assistant.role == .assistant)
        #expect(user.content == "x")
    }

    @Test func messageIdentifiable() {
        let m = Message(role: .user, content: "hi")
        #expect(m.id != Message(role: .user, content: "hi").id)
    }
}
