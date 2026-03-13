//
//  ChatScreen.swift
//  Jarvis
//

import SwiftUI

/// Full chat experience: header, orb, conversation and input.
struct ChatScreen: View {
    @Bindable var controller: AssistantController
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            AnimatedBackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 12) {
                header

                ChatView(controller: controller, showText: appState.settings.showText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)

                voiceBar
            }
        }
        .safeAreaInset(edge: .bottom) {
            ChatInputBar(controller: controller) { text in
                Task { await controller.sendText(text) }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.jarvisAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("JARVIS")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text("Local AI assistant")
                        .font(.caption)
                        .foregroundStyle(Color.jarvisSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var voiceBar: some View {
        VStack(spacing: 8) {
            WaveformView(level: controller.state == .listening ? 0.7 : 0.2, isActive: controller.state == .listening)
                .padding(.horizontal, 32)

            if controller.state == .listening {
                Text(controller.partialTranscript.isEmpty ? "Listening…" : controller.partialTranscript)
                    .font(.footnote)
                    .foregroundStyle(Color.jarvisSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
            }
            Spacer(minLength: 12)
        }
    }
}

