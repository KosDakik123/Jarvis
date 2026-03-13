//
//  HoldToTalkButton.swift
//  Jarvis
//

import SwiftUI

struct HoldToTalkButton: View {
    let title: String
    let isListening: Bool
    let onPressBegan: () -> Void
    let onPressEnded: () -> Void

    @State private var isPressed = false

    var body: some View {
        Text(isListening ? "Listening…" : title)
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(
                Circle()
                    .fill(isListening ? Color.jarvisGreen : Color.jarvisAccent.opacity(0.85))
                    .scaleEffect(isPressed ? 1.04 : 1.0)
            )
            .overlay(
                Circle()
                    .stroke(Color.jarvisAccent, lineWidth: 2)
                    .opacity(0.35)
            )
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPressBegan()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onPressEnded()
                    }
            )
            .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 20) {
        HoldToTalkButton(title: "Hold to talk", isListening: false, onPressBegan: {}, onPressEnded: {})
        HoldToTalkButton(title: "Hold to talk", isListening: true, onPressBegan: {}, onPressEnded: {})
    }
    .padding()
    .background(Color.jarvisBackground)
}

