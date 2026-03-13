//
//  OnboardingView.swift
//  Jarvis
//

import SwiftUI

struct OnboardingView: View {
    @Bindable var appState: AppState
    var onComplete: () -> Void
    @State private var micGranted: Bool?
    @State private var speechGranted: Bool?
    @State private var isRequesting = false

    var body: some View {
        EmptyView()
    }

    private func permissionRow(title: String, value: Bool?) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Text(label(for: value))
                .font(.callout.weight(.medium))
                .foregroundStyle(color(for: value))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.jarvisSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func label(for value: Bool?) -> String {
        switch value {
        case .none: return "Unknown"
        case .some(true): return "Allowed"
        case .some(false): return "Denied"
        }
    }

    private func color(for value: Bool?) -> Color {
        switch value {
        case .none: return Color.jarvisSecondary
        case .some(true): return Color.jarvisGreen
        case .some(false): return Color.red.opacity(0.85)
        }
    }

    @MainActor
    private func requestPermissions() async {
        isRequesting = true
        let res = await PermissionsManager.requestAll()
        micGranted = res.mic
        speechGranted = res.speech
        isRequesting = false
    }
}
