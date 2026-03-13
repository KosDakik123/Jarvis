//
//  StreamingTextView.swift
//  Jarvis
//

import SwiftUI

/// Text that appears token-by-token with subtle fade-in.
struct StreamingTextView: View {
    let text: String
    var tokenDelay: Double = 0.02

    var body: some View {
        Text(text)
            .textSelection(.enabled)
            .animation(.easeIn(duration: 0.15), value: text)
    }
}

#Preview {
    StreamingTextView(text: "Hello, I am JARVIS.")
        .padding()
        .background(Color.jarvisBackground)
}
