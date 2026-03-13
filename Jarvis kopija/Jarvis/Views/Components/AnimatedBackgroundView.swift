//
//  AnimatedBackgroundView.swift
//  Jarvis
//

import SwiftUI

/// Sci‑fi animated background with moving gradient blobs.
struct AnimatedBackgroundView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                LinearGradient(
                    colors: [
                        Color.jarvisBackground,
                        Color.black.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                movingBlob(color: .jarvisAccent.opacity(0.45), t: t, xFreq: 0.3, yFreq: 0.2, baseSize: 260)
                movingBlob(color: .jarvisPurple.opacity(0.35), t: t + 10, xFreq: 0.25, yFreq: 0.27, baseSize: 220)
                movingBlob(color: .jarvisCyan.opacity(0.30), t: t + 20, xFreq: 0.18, yFreq: 0.22, baseSize: 240)
            }
            .ignoresSafeArea()
        }
    }

    private func movingBlob(
        color: Color,
        t: TimeInterval,
        xFreq: Double,
        yFreq: Double,
        baseSize: CGFloat
    ) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let x = w * (0.5 + 0.25 * sin(t * xFreq))
            let y = h * (0.5 + 0.3  * cos(t * yFreq))
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color, .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: baseSize * 0.8
                    )
                )
                .frame(width: baseSize, height: baseSize)
                .position(x: x, y: y)
                .blur(radius: 40)
        }
    }
}

#Preview {
    AnimatedBackgroundView()
}

