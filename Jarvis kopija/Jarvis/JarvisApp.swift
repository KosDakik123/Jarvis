//
//  JarvisApp.swift
//  Jarvis
//

import SwiftUI
import SwiftData

@main
struct JarvisApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(appState)
        }
        .modelContainer(for: [ConversationEntity.self, MessageEntity.self])
    }
}
