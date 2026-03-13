//
//  AppState.swift
//  Jarvis
//

import SwiftUI
import SwiftData

/// Global app state — onboarding completed, selected model path, etc.
@Observable
final class AppState {
    var hasCompletedOnboarding: Bool
    var selectedModelPath: URL?
    var settings: AssistantSettings

    init(
        hasCompletedOnboarding: Bool = false,
        selectedModelPath: URL? = nil,
        settings: AssistantSettings = .default
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedModelPath = selectedModelPath
        self.settings = settings
    }
}
