//
//  PromptFormatter.swift
//  Jarvis
//

import Foundation

/// Chat template format (Llama 3 vs ChatML).
enum ChatTemplate: String, Sendable {
    case llama3
    case chatML
}

/// Formats system prompt + conversation history into model input.
enum PromptFormatter: Sendable {

    private static let llama3SystemStart = "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n"
    private static let llama3SystemEnd = "<|eot_id|>\n"
    private static let llama3UserStart = "<|start_header_id|>user<|end_header_id|>\n"
    private static let llama3UserEnd = "<|eot_id|>\n"
    private static let llama3AssistantStart = "<|start_header_id|>assistant<|end_header_id|>\n"

    private static let chatMLSystemStart = "<|im_start|>system\n"
    private static let chatMLSystemEnd = "<|im_end|>\n"
    private static let chatMLUserStart = "<|im_start|>user\n"
    private static let chatMLUserEnd = "<|im_end|>\n"
    private static let chatMLAssistantStart = "<|im_start|>assistant\n"

    /// Build full prompt for the given template.
    static func format(
        systemPrompt: String,
        messages: [Message],
        template: ChatTemplate = .llama3
    ) -> String {
        switch template {
        case .llama3:
            return formatLlama3(systemPrompt: systemPrompt, messages: messages)
        case .chatML:
            return formatChatML(systemPrompt: systemPrompt, messages: messages)
        }
    }

    private static func formatLlama3(systemPrompt: String, messages: [Message]) -> String {
        var out = llama3SystemStart + systemPrompt + llama3SystemEnd
        for msg in messages where msg.role != .system {
            switch msg.role {
            case .user:
                out += llama3UserStart + msg.content + llama3UserEnd
            case .assistant:
                out += llama3AssistantStart + msg.content + llama3UserEnd
            case .system:
                break
            }
        }
        out += llama3AssistantStart
        return out
    }

    private static func formatChatML(systemPrompt: String, messages: [Message]) -> String {
        var out = chatMLSystemStart + systemPrompt + chatMLSystemEnd
        for msg in messages where msg.role != .system {
            switch msg.role {
            case .user:
                out += chatMLUserStart + msg.content + chatMLUserEnd
            case .assistant:
                out += chatMLAssistantStart + msg.content + chatMLUserEnd
            case .system:
                break
            }
        }
        out += chatMLAssistantStart
        return out
    }

    /// Infer template from model file name (e.g. llama → llama3, phi → chatML).
    static func template(forModelFileName name: String) -> ChatTemplate {
        let lower = name.lowercased()
        if lower.contains("llama") && (lower.contains("3") || lower.contains("3.2")) {
            return .llama3
        }
        if lower.contains("phi") || lower.contains("mistral") || lower.contains("gemma") {
            return .chatML
        }
        return .llama3
    }
}
