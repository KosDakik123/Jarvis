//
//  MainView.swift
//  Jarvis
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var assistantController: AssistantController
    @State private var engine: LLMEngine
    @State private var selectedTab: Int = 0

    init() {
        let engine = LLMEngine()
        let conv = ConversationManager()
        _engine = State(initialValue: engine)
        _assistantController = State(initialValue: AssistantController(engine: engine, conversationManager: conv))
    }

    var body: some View {
        @Bindable var controller = assistantController
        TabView(selection: $selectedTab) {
            ChatScreen(controller: controller)
                .tag(0)
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }

            HistoryView(controller: controller, selectedTab: $selectedTab)
                .tag(1)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            SettingsView(appState: appState, controller: controller)
                .tag(2)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .task {
            assistantController.setModelPath(appState.selectedModelPath)
            await assistantController.loadModelIfNeeded()
            assistantController.applySettings(
                voiceId: appState.settings.voiceIdentifier,
                rate: appState.settings.speechRate,
                autoListen: appState.settings.autoListenAfterResponse
            )
            assistantController.setWakeWordEnabled(appState.settings.wakeWordEnabled)
            assistantController.attachPersistence(modelContext)
        }
        .onChange(of: appState.selectedModelPath) { _, newPath in
            assistantController.setModelPath(newPath)
            Task { await assistantController.loadModelIfNeeded() }
        }
        .onChange(of: appState.settings.voiceIdentifier) { _, id in
            assistantController.applySettings(voiceId: id, rate: appState.settings.speechRate, autoListen: appState.settings.autoListenAfterResponse)
        }
        .onChange(of: appState.settings.speechRate) { _, rate in
            assistantController.applySettings(voiceId: appState.settings.voiceIdentifier, rate: rate, autoListen: appState.settings.autoListenAfterResponse)
        }
        .onChange(of: appState.settings.autoListenAfterResponse) { _, auto in
            assistantController.applySettings(voiceId: appState.settings.voiceIdentifier, rate: appState.settings.speechRate, autoListen: auto)
        }
        .onChange(of: appState.settings.wakeWordEnabled) { _, enabled in
            assistantController.setWakeWordEnabled(enabled)
        }
        .alert(
            "Voice input error",
            isPresented: Binding(
                get: { assistantController.errorMessage != nil },
                set: { if !$0 { assistantController.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            let raw = assistantController.errorMessage ?? ""
            if raw.lowercased().contains("recognition request was cancelled") {
                Text("Listening stopped.")
            } else {
                Text(raw)
            }
        }
    }
}
