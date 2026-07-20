//
//  Wrappers.swift
//  VerticalSplit
//
//  Card-wrapping containers that produce the floating-pane effect:
//  scale, blur, corner-radius animation, and safe-area-aware padding.
//  Ported from Doit's VerticalSplit component (simplified for bible-app).
//

import SwiftUI

// MARK: - TopWrapper

struct TopWrapper<Content: View, Overlay: View>: View {
    var minimise: CGFloat       // 0 = normal, 1 = fully minimised
    var overscroll: CGFloat
    var isFull: Bool            // bottom pane collapsed → top goes full-screen
    var bgColor: Color
    @ViewBuilder var content: () -> Content
    @ViewBuilder var overlay: () -> Overlay

    let bottomSafeArea = SafeAreaInsetsKey.defaultValue.bottom
    /// Approximates the device's display corner radius for the pane mask.
    let displayCornerRadius: CGFloat = 44
    let screenWidth = UIApplication.shared.screenSize.width

    var cornerRadius: CGFloat {
        isFull ? displayCornerRadius + overscroll * 2 : 22
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                content()
            }
            .frame(maxWidth: screenWidth, maxHeight: .infinity, alignment: .top)
            .safeAreaPadding(.top, SafeAreaInsetsKey.defaultValue.top)
            .safeAreaPadding(.bottom, isFull ? 58 + bottomSafeArea - 8 : 0)
        }
        .scaleEffect(1 - (1 - minimise) * 0.15, anchor: .top)
        .blur(radius: (1 - minimise) * 8)
        .overlay { bgColor.opacity(1 - minimise).allowsHitTesting(false) }
        .overlay(alignment: .bottom, content: {
            overlay()
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 58)
                .opacity(1 - minimise)
                .blur(radius: minimise * 8)
                .offset(y: 16 * minimise)
                .scaleEffect(1 + minimise * 0.15)
                .allowsHitTesting(minimise == 0)
        })
        .mask { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(bgColor)
                .padding(.top, -200)
        }
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .scaleEffect(isFull ? 1 : 1 + min(0, overscroll / 800), anchor: isFull ? .center : .bottom)
        .ignoresSafeArea()
    }
}

// MARK: - BottomWrapper

struct BottomWrapper<Content: View, Overlay: View>: View {
    var minimise: CGFloat       // 0 = normal, 1 = fully minimised
    var overscroll: CGFloat
    var isFull: Bool            // top pane collapsed → bottom goes full-screen
    var bgColor: Color
    @ViewBuilder var content: () -> Content
    @ViewBuilder var overlay: () -> Overlay

    let topSafeArea = SafeAreaInsetsKey.defaultValue.top
    /// Approximates the device's display corner radius for the pane mask.
    let displayCornerRadius: CGFloat = 44
    let screenWidth = UIApplication.shared.screenSize.width

    var cornerRadius: CGFloat {
        isFull ? displayCornerRadius - overscroll * 2 : 22
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                content()
            }
            .frame(maxWidth: screenWidth, maxHeight: .infinity, alignment: .top)
            .safeAreaPadding(.top, isFull ? 58 + topSafeArea - 8 : 0)
            .safeAreaPadding(.bottom, SafeAreaInsetsKey.defaultValue.bottom)
        }
        .scaleEffect(1 - (1 - minimise) * 0.15, anchor: .bottom)
        .blur(radius: (1 - minimise) * 8)
        .overlay { bgColor.opacity(1 - minimise).allowsHitTesting(false) }
        .overlay(alignment: .top, content: {
            overlay()
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 58)
                .opacity(1 - minimise)
                .blur(radius: minimise * 8)
                .offset(y: -16 * minimise)
                .scaleEffect(1 + minimise * 0.15)
                .allowsHitTesting(minimise == 0)
        })
        .mask { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(bgColor)
                .padding(.bottom, -200)
        }
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: -4)
        .scaleEffect(isFull ? 1 : 1 - max(0, overscroll / 800), anchor: isFull ? .center : .top)
        .ignoresSafeArea()
    }
}
