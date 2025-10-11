//
//  DetectKeyboard.swift
//  Deadlift Diaries
//
//  Created by Jerroder on 2025-09-29.
//

import SwiftUI

struct DetectKeyboard: ViewModifier {
    @Binding var isKeyboardShowing: Bool
    @State private var bottomInsetWithoutKeyboard: CGFloat?
    @State private var bottomInsetWithKeyboard: CGFloat?
    
    private var isKeyboardDetected: Bool {
        if let bottomInsetWithoutKeyboard, let bottomInsetWithKeyboard {
            bottomInsetWithoutKeyboard != bottomInsetWithKeyboard
        } else {
            false
        }
    }
    
    func body(content: Content) -> some View {
        ZStack {
            Color.clear
                .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.bottom) { bottomInset in
                    bottomInsetWithoutKeyboard = bottomInset
                }
                .ignoresSafeArea(.keyboard)
            Color.clear
                .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.bottom) { bottomInset in
                    bottomInsetWithKeyboard = bottomInset
                }
            content
        }
        .onChange(of: isKeyboardDetected) { _, newVal in
            isKeyboardShowing = newVal
        }
    }
}

extension View {
    func detectKeyboard(isKeyboardShowing: Binding<Bool>) -> some View {
        modifier(DetectKeyboard(isKeyboardShowing: isKeyboardShowing))
    }
}
