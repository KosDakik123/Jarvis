//
//  OrbView.swift
//  Jarvis
//

import SwiftUI

/// Animated orb that reacts to assistant state.
struct OrbView: View {
    let state: AssistantState

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            OrbContent(state: state, date: context.date)
        }
    }
}

// MARK: - Extracted subview to avoid type-checker timeout

private struct OrbContent: View {
    let state: AssistantState
    let date: Date

    private var t: Double {
        date.timeIntervalSinceReferenceDate
    }

    var body: some View {
        ZStack {
            outerGlow
            if state == .listening {
                listeningRings
            }
            mainOrb
        }
    }

    // MARK: - Orb Color

    private var orbColor: Color {
        switch state {
        case .idle:      return .jarvisIdle
        case .listening: return .jarvisGreen
        case .thinking:  return .jarvisPurple
        case .speaking:  return .jarvisCyan
        }
    }

    // MARK: - Outer Glow

    private var outerGlow: some View {
        Circle()
            .fill(orbColor.opacity(0.3))
            .frame(width: 160, height: 160)
            .blur(radius: 30)
            .scaleEffect(1.0 + 0.08 * sin(t * 1.2))
    }

    // MARK: - Listening Rings

    private var listeningRings: some View {
        ForEach(0..<3, id: \.self) { i in
            ListeningRing(index: i, time: t, color: orbColor)
        }
    }

    // MARK: - Main Orb

    private var mainOrb: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        orbColor.opacity(0.95),
                        orbColor.opacity(0.5),
                        orbColor.opacity(0.2)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 55
                )
            )
            .frame(width: 110, height: 110)
            .scaleEffect(orbScale)
            .shadow(color: orbColor.opacity(0.5), radius: 20)
    }

    // MARK: - Orb Scale

    private var orbScale: CGFloat {
        switch state {
        case .idle:      return 1.0 + 0.03 * sin(t * 0.8)
        case .listening: return 1.05 + 0.06 * sin(t * 2.0)
        case .thinking:  return 1.02 + 0.04 * sin(t * 1.5)
        case .speaking:  return 1.04 + 0.05 * sin(t * 3.0)
        }
    }
}

// MARK: - Individual Listening Ring

private struct ListeningRing: View {
    let index: Int
    let time: Double
    let color: Color

    private var size: CGFloat {
        let base: CGFloat = 100 + CGFloat(index) * 25
        let wave: CGFloat = 15 * sin(time + Double(index))
        return base + wave
    }

    private var ringOpacity: Double {
        0.6 - Double(index) * 0.15
    }

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .frame(width: size, height: size)
            .opacity(ringOpacity)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        OrbView(state: .idle)
        OrbView(state: .listening)
        OrbView(state: .thinking)
        OrbView(state: .speaking)
    }
    .padding(40)
    .background(Color.jarvisBackground)
}
