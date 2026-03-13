//
//  AssistantController.swift
//  Jarvis
//

import Foundation
import SwiftData

/// UI-facing state for the assistant.
enum AssistantState: Sendable {
    case idle
    case listening
    case thinking
    case speaking
}

/// Orchestrates STT → LLM → TTS.
@Observable
@MainActor
final class AssistantController {

    var state: AssistantState = .idle
    var messages: [Message] { conversationManager.conversation.messages }
    var streamingContent: String = ""
    var partialTranscript: String = ""
    var errorMessage: String?

    private let engine: LLMEngine
    private let conversationManager: ConversationManager
    private var modelPath: URL?
    private var currentTemplate: ChatTemplate = .llama3
    private let speechRecognizer = SpeechRecognizer()
    private let speechSynthesizer = SpeechSynthesizer()
    private var autoListenAfterResponse: Bool = false
    private var isStartingListening = false
    private var wakeWordEnabled: Bool = false
    private var isWakeWordSessionActive: Bool = false
    private var modelContext: ModelContext?
    private var currentConversationEntity: ConversationEntity?

    init(engine: LLMEngine, conversationManager: ConversationManager) {
        self.engine = engine
        self.conversationManager = conversationManager
        setupSpeechCallbacks()
    }

    func attachPersistence(_ context: ModelContext) {
        modelContext = context
        // Try to reuse the most recent conversation, otherwise create a new one.
        if currentConversationEntity == nil {
            let descriptor = FetchDescriptor<ConversationEntity>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            if let existing = try? context.fetch(descriptor).first {
                currentConversationEntity = existing
            } else {
                let convo = ConversationEntity(title: "New chat")
                context.insert(convo)
                currentConversationEntity = convo
            }
        }
    }

    private func persistMessage(_ message: Message) {
        guard let context = modelContext else { return }
        let convo: ConversationEntity
        if let existing = currentConversationEntity {
            convo = existing
        } else {
            let c = ConversationEntity(title: "New chat")
            context.insert(c)
            currentConversationEntity = c
            convo = c
        }
        let entity = MessageEntity(role: message.role.rawValue, content: message.content)
        convo.messages.insert(entity, at: 0)
        if convo.title == "New chat", message.role == .user {
            convo.title = String(message.content.prefix(40))
        }
        convo.updatedAt = Date()
    }

    func setAutoListenAfterResponse(_ value: Bool) {
        autoListenAfterResponse = value
    }

    func setWakeWordEnabled(_ value: Bool) {
        wakeWordEnabled = value
        if value {
            startWakeWordIfNeeded()
        } else {
            if isWakeWordSessionActive {
                speechRecognizer.stop()
                isWakeWordSessionActive = false
                setupSpeechCallbacks()
            }
        }
    }

    private func setupSpeechCallbacks() {
        speechRecognizer.onPartialResult = { [weak self] text in
            Task { @MainActor in
                self?.partialTranscript = text
            }
        }
        speechRecognizer.onFinalResult = { [weak self] text in
            Task { @MainActor in
                self?.partialTranscript = ""
                let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { await self?.sendText(t) }
            }
        }
        speechRecognizer.onError = { [weak self] err in
            Task { @MainActor in
                self?.state = .idle
                self?.partialTranscript = ""
                self?.errorMessage = err.localizedDescription
            }
        }
        speechSynthesizer.onFinish = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.state = .idle
                self.startWakeWordIfNeeded()
            }
        }
    }

    func startListening() {
        guard state != .thinking else { return }
        guard !isStartingListening else { return }
        if state == .listening { return }
        // If a wake-word session is active, stop it before starting a focused query.
        if isWakeWordSessionActive {
            speechRecognizer.stop()
            isWakeWordSessionActive = false
            setupSpeechCallbacks()
        }
        speechSynthesizer.stop()
        partialTranscript = ""
        errorMessage = nil
        isStartingListening = true

        Task { @MainActor in
            let perms = await PermissionsManager.requestAll()
            guard perms.mic else {
                self.errorMessage = "Microphone permission is required."
                self.state = .idle
                self.isStartingListening = false
                return
            }
            guard perms.speech else {
                self.errorMessage = "Speech recognition permission is required."
                self.state = .idle
                self.isStartingListening = false
                return
            }
            do {
                try self.speechRecognizer.start()
                self.state = .listening
            } catch {
                self.errorMessage = error.localizedDescription
                self.state = .idle
            }
            self.isStartingListening = false
        }
    }

    func stopListening() {
        guard state == .listening else { return }
        speechRecognizer.stop()
        state = .idle
        partialTranscript = ""
    }

    func setModelPath(_ path: URL?) {
        modelPath = path
        if let path {
            currentTemplate = PromptFormatter.template(forModelFileName: path.lastPathComponent)
        }
    }

    /// Load model at path (call after picking model in settings).
    func loadModelIfNeeded() async {
        guard let path = modelPath else { return }
        do {
            let config = LLMConfiguration.default
            // Could bind config to settings later
            try await engine.loadModel(at: path, config: config)
        } catch {
            // Surface error to UI if needed
        }
    }

    /// Send user text and stream assistant reply.
    func sendText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = Message(role: .user, content: trimmed)
        conversationManager.append(userMessage)
        persistMessage(userMessage)
        state = .thinking
        streamingContent = ""

        let systemPrompt = SystemPrompt.jarvis
        let history = conversationManager.trimmedMessages()
        let prompt = PromptFormatter.format(
            systemPrompt: systemPrompt,
            messages: history,
            template: currentTemplate
        )

        var fullReply = ""
        for await token in await engine.generate(prompt: prompt) {
            fullReply += token
            streamingContent = fullReply
        }

        let cleaned = cleanLLMOutput(fullReply)
        let reply = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        if !reply.isEmpty {
            let msg = Message(role: .assistant, content: reply)
            conversationManager.append(msg)
            persistMessage(msg)
            state = .speaking
            // Always speak the reply so voice users hear the answer.
            speechSynthesizer.speak(reply)
        } else {
            state = .idle
        }
        streamingContent = ""
    }

    // MARK: - Wake word ("Hey Jarvis") handling

    private func startWakeWordIfNeeded() {
        guard wakeWordEnabled else { return }
        guard !isWakeWordSessionActive else { return }
        // Only listen for wake word when we're idle so we don't fight with active conversations.
        guard state == .idle else { return }

        isWakeWordSessionActive = true
        partialTranscript = ""
        errorMessage = nil

        // Override recognizer callbacks for wake-word mode.
        speechRecognizer.onPartialResult = { [weak self] text in
            Task { @MainActor in
                self?.handleWakeWord(text: text, isFinal: false)
            }
        }
        speechRecognizer.onFinalResult = { [weak self] text in
            Task { @MainActor in
                self?.handleWakeWord(text: text, isFinal: true)
            }
        }
        speechRecognizer.onError = { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isWakeWordSessionActive = false
                // Try again if still enabled and idle.
                self.startWakeWordIfNeeded()
            }
        }

        Task { @MainActor in
            do {
                try self.speechRecognizer.start()
            } catch {
                self.errorMessage = error.localizedDescription
                self.isWakeWordSessionActive = false
            }
        }
    }

    private func handleWakeWord(text: String, isFinal: Bool) {
        let lower = text.lowercased()
        // If no wake phrase was heard and this is a final result (silence timeout),
        // restart the wake-word listener so it keeps running while the app is open.
        guard let range = lower.range(of: "hey jarvis") else {
            if isFinal {
                isWakeWordSessionActive = false
                startWakeWordIfNeeded()
            }
            return
        }

        // Grab everything after the wake phrase as the actual question.
        let after = text[range.upperBound...]
        let cleanedQuestion = after
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ",.?! "))

        speechRecognizer.stop()
        isWakeWordSessionActive = false
        // Restore normal STT → sendText pipeline.
        setupSpeechCallbacks()

        if !cleanedQuestion.isEmpty {
            Task { await self.sendText(String(cleanedQuestion)) }
        } else if isFinal {
            // If user only said the wake word, start normal listening so they can ask.
            startListening()
        }
    }

    /// Strip special chat template tokens so the user doesn't see them.
    private func cleanLLMOutput(_ text: String) -> String {
        var out = text

        // 1) Hard cut at known end markers so we don't keep extra chat turns.
        let endMarkers = [
            "<|eot_id|>",
            "<eot_id>",
            "<|im_end|>"
        ]
        if let cutIndex = endMarkers
            .compactMap({ out.range(of: $0)?.lowerBound })
            .sorted(by: { $0 < $1 })
            .first {
            out = String(out[..<cutIndex])
        }

        // 2) Remove special template tokens entirely.
        let junkTokens = [
            "<|begin_of_text|>",
            "<|start_header_id|>",
            "<|end_header_id|>",
            "<|eot_id|>",
            "<eot_id>",
            "<|im_start|>",
            "<|im_end|>"
        ]
        for token in junkTokens {
            out = out.replacingOccurrences(of: token, with: "")
        }

        // 3) If the model started writing another turn ("user", "assistant"), drop that.
        let roleMarkers = [
            "\nuser\n",
            "\nuser:",
            "\nUser:",
            "\nassistant\n",
            "\nassistant:",
            "\nAssistant:"
        ]
        if let cutIndex = roleMarkers
            .compactMap({ out.range(of: $0)?.lowerBound })
            .sorted(by: { $0 < $1 })
            .first {
            out = String(out[..<cutIndex])
        }

        return out
    }

    func applySettings(voiceId: String, rate: Float, autoListen: Bool) {
        speechSynthesizer.voiceIdentifier = voiceId
        speechSynthesizer.rate = rate
        autoListenAfterResponse = autoListen
    }

    func clearConversation() {
        conversationManager.clear()
        streamingContent = ""
        partialTranscript = ""
        errorMessage = nil
        state = .idle
    }
}
