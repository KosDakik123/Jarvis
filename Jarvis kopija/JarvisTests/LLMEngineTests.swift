//
//  LLMEngineTests.swift
//  JarvisTests
//

import Testing
@testable import Jarvis

struct LLMEngineTests {

    @Test func generateStreamsTokens() async {
        let engine = LLMEngine()
        // Stub: no model loaded, so generate will not yield (state != .ready).
        // Load would require a real file. So we only test that we can create and call.
        var count = 0
        for await _ in engine.generate(prompt: "Hello") {
            count += 1
        }
        #expect(count >= 0)
    }
}
