//
//  PulsatingButton.swift
//  Jarvis
//

import SwiftUI

struct PulsatingButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isActive ? .white : .primary)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    Circle()
                        .fill(isActive ? Color.jarvisGreen : Color.jarvisSurface)
                        .scaleEffect(isActive && isPulsing ? 1.05 : 1.0)
                )
                .overlay(
                    Circle()
                        .stroke(Color.jarvisAccent, lineWidth: 2)
                        .opacity(isActive ? 0.8 : 0.3)
                )
        }
        .buttonStyle(.plain)
        .onChange(of: isActive) { _, newValue in
            guard newValue else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PulsatingButton(title: "Tap to talk", isActive: false, action: {})
        PulsatingButton(title: "Listening…", isActive: true, action: {})
    }
    .padding()
    .background(Color.jarvisBackground)
}
