//
//  View+Animations.swift
//  Jarvis
//

import SwiftUI

extension View {
    /// Slide in from bottom with spring.
    func jarvisMessageTransition() -> some View {
        transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
    }
}
