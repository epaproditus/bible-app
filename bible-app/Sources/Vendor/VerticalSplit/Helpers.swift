//
//  Helpers.swift
//  VerticalSplit
//
//  UIKit bridge helpers for safe-area and screen geometry.
//  Adapted from Doit's VerticalSplit component.
//

import UIKit
import SwiftUI

// MARK: - Safe Area

struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        UIApplication.shared.safeAreaInsets.insets
    }
}

extension EdgeInsets {
    var vertical: CGFloat { top + bottom }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

extension UIEdgeInsets {
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

extension UIApplication {
    var screenSize: CGSize {
        let scenes = connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.screen.bounds.size ?? UIScreen.main.bounds.size
    }

    var safeAreaInsets: UIEdgeInsets {
        let scenes = connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.safeAreaInsets ?? UIEdgeInsets.zero
    }
}

// MARK: - Button Style

struct ScaleDownButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .animation(.smooth(duration: configuration.isPressed ? 0.1 : 0.2), value: configuration.isPressed)
    }
}
