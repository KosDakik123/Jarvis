//
//  WaveformView.swift
//  Jarvis
//

import SwiftUI

/// Real-time waveform placeholder; bind to audio levels later.
struct WaveformView: View {
    var level: Float = 0.3
    var isActive: Bool = false
    var barCount: Int = 32

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width / CGFloat(barCount)
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.jarvisAccent.opacity(barOpacity(i: i)))
                        .frame(width: max(2, width - 2), height: barHeight(i: i, maxHeight: geo.size.height))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 44)
    }

    private func barHeight(i: Int, maxHeight: CGFloat) -> CGFloat {
        let seed = sin(Double(i) * 0.7) * 0.5 + 0.5
        let scale = isActive ? CGFloat(level) * 1.2 + 0.2 : 0.15
        return max(4, maxHeight * CGFloat(seed) * scale)
    }

    private func barOpacity(i: Int) -> Double {
        isActive ? 0.6 + 0.4 * sin(Double(i) * 0.3) : 0.25
    }
}

#Preview {
    VStack {
        WaveformView(level: 0.3, isActive: false)
        WaveformView(level: 0.7, isActive: true)
    }
    .padding()
    .background(Color.jarvisBackground)
}
