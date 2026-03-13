//
//  PromptFormatterTests.swift
//  JarvisTests
//

import Testing
@testable import Jarvis

struct PromptFormatterTests {

    @Test func llama3FormatIncludesSystemAndUser() {
        let messages = [Message(role: .user, content: "Hello")]
        let out = PromptFormatter.format(systemPrompt: "You are helpful.", messages: messages, template: .llama3)
        #expect(out.contains("You are helpful."))
        #expect(out.contains("Hello"))
        #expect(out.contains("<|start_header_id|>system"))
        #expect(out.contains("<|start_header_id|>user"))
        #expect(out.contains("<|start_header_id|>assistant"))
    }

    @Test func chatMLFormatIncludesMarkers() {
        let messages = [Message(role: .user, content: "Hi")]
        let out = PromptFormatter.format(systemPrompt: "Sys", messages: messages, template: .chatML)
        #expect(out.contains("<|im_start|>system"))
        #expect(out.contains("<|im_start|>user"))
        #expect(out.contains("<|im_start|>assistant"))
        #expect(out.contains("Hi"))
    }

    @Test func templateForModelName() {
        #expect(PromptFormatter.template(forModelFileName: "llama-3.2-3b.gguf") == .llama3)
        #expect(PromptFormatter.template(forModelFileName: "phi-3-mini.gguf") == .chatML)
    }
}
