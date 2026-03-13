//
//  SettingsView.swift
//  Jarvis
//

import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    @Bindable var controller: AssistantController
    @State private var showWorkspace = false
    @State private var showModelHelp = false

    var body: some View {
        NavigationStack {
            List {
                Section("Model") {
                    Picker("Model", selection: Binding(
                        get: { appState.selectedModelPath },
                        set: { appState.selectedModelPath = $0 }
                    )) {
                        Text("None (stub)").tag(Optional<URL>.none)
                        ForEach(ModelManager.listAvailableModels(), id: \.self) { url in
                            Text(ModelManager.displayName(for: url))
                                .tag(Optional(url))
                        }
                    }
                    .pickerStyle(.menu)
                    Text("Select a local GGUF model file. Larger models are smarter but use more memory and battery.")
                        .font(.caption)
                        .foregroundStyle(Color.jarvisSecondary)
                }

                Section("Voice") {
                    Text("Voice: System default")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { Double(appState.settings.speechRate) },
                        set: { appState.settings.speechRate = Float($0) }
                    ), in: 0...1)
                    .padding(.vertical, 4)
                    Text("Controls how fast JARVIS speaks. Lower is slower and easier to follow.")
                        .font(.caption)
                        .foregroundStyle(Color.jarvisSecondary)
                }

                Section("LLM") {
                    Slider(value: Binding(
                        get: { Double(appState.settings.temperature) },
                        set: { appState.settings.temperature = Float($0) }
                    ), in: 0...1)
                    .padding(.vertical, 4)
                    Text("Temperature: lower = more focused and deterministic, higher = more creative but less reliable.")
                        .font(.caption)
                        .foregroundStyle(Color.jarvisSecondary)

                    Slider(value: Binding(
                        get: { Double(appState.settings.maxTokens) },
                        set: { appState.settings.maxTokens = Int($0) }
                    ), in: 64...1024, step: 64)
                    .padding(.vertical, 4)
                    Text("Max response length: how many tokens JARVIS is allowed to generate per reply. Shorter replies feel snappier.")
                        .font(.caption)
                        .foregroundStyle(Color.jarvisSecondary)
                }

                Section("Behavior") {
                    Toggle("Auto-listen after response", isOn: Binding(
                        get: { appState.settings.autoListenAfterResponse },
                        set: { appState.settings.autoListenAfterResponse = $0 }
                    ))
                    Toggle("Hey JARVIS wake word (in app)", isOn: Binding(
                        get: { appState.settings.wakeWordEnabled },
                        set: { appState.settings.wakeWordEnabled = $0 }
                    ))
                    Toggle("Show text", isOn: Binding(
                        get: { appState.settings.showText },
                        set: { appState.settings.showText = $0 }
                    ))
                    Toggle("Enable camera + workspace", isOn: Binding(
                        get: { appState.settings.cameraEnabled },
                        set: { appState.settings.cameraEnabled = $0 }
                    ))
                }

                Section("Workspace") {
                    Button("Open workspace") { showWorkspace = true }
                }

                Section {
                    Button("Download additional models", role: .none) {
                        showModelHelp = true
                    }
                }

                Section {
                    Button("Clear conversation history", role: .destructive) {
                        controller.clearConversation()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.jarvisBackground)
            .sheet(isPresented: $showWorkspace) {
                WorkspaceView()
            }
            .sheet(isPresented: $showModelHelp) {
                ModelDownloadHelpView()
            }
        }
    }
}
