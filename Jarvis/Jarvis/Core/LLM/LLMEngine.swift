//
//  LLMEngine.swift
//  Jarvis
//
import Foundation
import llama

/// Engine state for UI binding.
enum LLMEngineState: Sendable {
    case idle
    case loading
    case ready
    case generating
    case error(Error)
}

/// Errors from the LLM layer.
struct LLMEngineError: Error, Sendable {
    let message: String
}

/// Thread-safe LLM engine: load GGUF via llama.cpp and stream tokens.
actor LLMEngine {

    private(set) var state: LLMEngineState = .idle
    private var modelPath: URL?
    private var config: LLMConfiguration = .default
    private var cancelRequested = false
    private var llamaContext: LlamaContext?

    /// Load model at path with given config. Runs on actor context (background).
    func loadModel(at path: URL, config: LLMConfiguration) async throws {
        state = .loading
        cancelRequested = false
        self.modelPath = path
        self.config = config

        guard FileManager.default.fileExists(atPath: path.path) else {
            state = .error(LLMEngineError(message: "Model file not found: \(path.path)"))
            throw LLMEngineError(message: "Model file not found")
        }

        do {
            let ctx = try LlamaContext.createContext(
                path: path.path,
                ctxSize: Int32(config.contextSize)
            )
            await ctx.configure(maxTokens: Int32(config.maxTokens))
            llamaContext = ctx
            state = .ready
        } catch {
            state = .error(error)
            throw error
        }
    }

    /// Stream generated tokens. Call from async context.
    func generate(prompt: String) -> AsyncStream<String> {
        AsyncStream { continuation in
            Task {
                await self._generate(prompt: prompt, continuation: continuation)
            }
        }
    }

    private func _generate(prompt: String, continuation: AsyncStream<String>.Continuation) async {
        guard let ctx = llamaContext else {
            // Fallback stub if model is not loaded.
            let stubResponse = "I'm JARVIS, but no model is loaded yet. Please select a GGUF model in Settings."
            for token in stubResponse.split(separator: " ").map(String.init) {
                if cancelRequested { break }
                continuation.yield(token + " ")
            }
            continuation.finish()
            return
        }

        state = .generating
        cancelRequested = false

        await ctx.clear()
        await ctx.completionInit(text: prompt)

        var steps = 0
        while !cancelRequested,
              let done = await ctx.isDone as Bool?,
              !done,
              steps < config.maxTokens {
            let piece = await ctx.completionStep()
            if !piece.isEmpty {
                continuation.yield(piece)
            }
            steps += 1
        }

        if !cancelRequested {
            state = .ready
        }
        continuation.finish()
    }

    func cancel() {
        cancelRequested = true
    }

    func unloadModel() {
        cancelRequested = true
        modelPath = nil
        state = .idle
    }

    /// Current config (for context window / truncation later).
    func currentConfig() -> LLMConfiguration {
        config
    }
}
