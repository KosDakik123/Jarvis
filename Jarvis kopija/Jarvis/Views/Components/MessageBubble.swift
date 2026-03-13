//
//  MessageBubble.swift
//  Jarvis
//

import SwiftUI
import UIKit

struct MessageBubble: View {
    let message: Message
    var isStreaming: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user { Spacer(minLength: 48) }
            if message.role == .assistant {
                Circle()
                    .fill(Color.jarvisAccent.opacity(0.9))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                HStack {
                    Text(message.role == .user ? "You" : "JARVIS")
                        .font(.caption)
                        .foregroundStyle(Color.jarvisSecondary)
                    if message.role == .assistant {
                        Button {
                            UIPasteboard.general.string = message.content
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(Color.jarvisSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(message.content)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(message.role == .user ? Color.white : Color(white: 0.95))
                    .multilineTextAlignment(message.role == .user ? .trailing : .leading)
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(backgroundColor)
                            .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 8)
                    )
            }
            if message.role == .assistant { Spacer(minLength: 48) }
            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.jarvisSecondary)
            }
        }
        .padding(.horizontal)
    }

    private var backgroundColor: Color {
        if message.role == .user {
            return Color.jarvisAccent.opacity(0.35)
        } else {
            return Color.black.opacity(0.30)
        }
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            MessageBubble(message: Message(role: .user, content: "What's the weather?"))
            MessageBubble(message: Message(role: .assistant, content: "I'm running locally — I don't have live weather data. You could ask Siri or check your weather app."))
        }
        .padding()
    }
    .background(Color.jarvisBackground)
}
