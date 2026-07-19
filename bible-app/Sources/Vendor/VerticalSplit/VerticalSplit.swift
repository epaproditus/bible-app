//
//  VerticalSplit.swift
//  VerticalSplit
//
//  A draggable-divider container ported from Doit's VerticalSplit component.
//  Provides 3 snap detents with smooth animation, floating-pane appearance,
//  black gap divider, and background dimming.
//
//  Detents (top pane fraction):
//    .topFull            — 1.0  (bottom collapsed)
//    .footnotesExpanded  — 5/6  (small bottom strip)
//    .footnotesFull      — 4/6  (larger bottom area)
//

import SwiftUI
import OSLog

private let log = Logger(subsystem: "bible-app.VerticalSplit", category: "Gesture")

/// The spacing gap between the two panes (acts as the drag-pill track).
private let spacing: CGFloat = 36

/// Minimum visual height for either pane before collapse logic kicks in.
private let lil: CGFloat = 58
private let lil2: CGFloat = 58 * 3 / 2
private let lil3: CGFloat = 58 * 2

/// Number of snap notches (0-based → notchCount+1 positions).
private let notches: Int = 2   // 0, 1, 2 → 3 detents

/// Haptic generators.
private let lightImpact = UIImpactFeedbackGenerator(style: .light)
private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)

// MARK: - VerticalSplit

public struct VerticalSplit<TopView: View, BottomView: View>: View {

    @ViewBuilder var topView: () -> TopView
    @ViewBuilder var bottomView: () -> BottomView

    let topTitle: String
    let bottomTitle: String

    @Binding var detent: SplitDetent

    /// Background tint for both pane surfaces.
    var bgColor: Color = Color(.systemBackground)

    // ── Gesture state ──

    @GestureState var isDragging: Bool = false

    @State var partition: CGFloat = 0
    @State var notchPartition: CGFloat = 0
    @State var initialPartition: CGFloat?
    @State var topHeight: CGFloat = 200
    @State var didSetInitialSplit = false

    @State var hideTop = false
    @State var hideBottom = false

    @State var overscroll: CGFloat = 0
    @State var translationBeforeOverscroll: CGFloat = 0
    @State var initialMinimal = false
    @State var initialTop: Bool = false

    /// Extra offset when there's no bottom safe area (e.g. older devices).
    let bottomExtraOffset: CGFloat = SafeAreaInsetsKey.defaultValue.bottom == 0 ? 16 : 0

    // ── Derived geometry ──

    private var usableHeight: CGFloat {
        let safe = SafeAreaInsetsKey.defaultValue
        return UIScreen.main.bounds.height - safe.vertical
    }

    /// Half-height of one pane at the 50/50 split (excluding spacing).
    private var cardHeight: CGFloat {
        (usableHeight - spacing) / 2
    }

    /// Maximum partition travel from center before we trigger collapse.
    private var range: CGFloat {
        cardHeight - lil
    }

    private let transaction: Transaction = {
        var t = Transaction(animation: .smooth(duration: 0.4))
        t.tracksVelocity = true
        t.isContinuous = true
        return t
    }()

    // MARK: - Gesture

    private var bossGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($isDragging) { _, s, _ in s = true }
            .onChanged { value in
                if initialPartition == nil {
                    initialPartition = partition
                    if hideTop || hideBottom {
                        initialMinimal = true
                        initialTop = hideTop
                        mediumImpact.impactOccurred(intensity: 0.6)
                    }
                }

                withTransaction(transaction) {
                    let translation = (initialPartition ?? 0) + value.translation.height
                    let minimalAdjustment = (initialMinimal ? (initialTop ? 8 - lil : lil - 8 - bottomExtraOffset) : 0)
                    let newPartition = min(cardHeight - lil,
                                           max(-cardHeight + lil, translation + minimalAdjustment))

                    // Overscroll buffer for collapsing
                    if translation < -cardHeight + lil {
                        if translationBeforeOverscroll == 0 {
                            translationBeforeOverscroll = translation
                            mediumImpact.impactOccurred(intensity: 0.8)
                        }
                        overscroll = (translation - translationBeforeOverscroll) * 0.75
                    } else if translation > cardHeight - lil {
                        if translationBeforeOverscroll == 0 {
                            translationBeforeOverscroll = translation
                            mediumImpact.impactOccurred(intensity: 0.8)
                        }
                        overscroll = (translation - translationBeforeOverscroll) * 0.75
                    } else {
                        translationBeforeOverscroll = 0
                        overscroll = 0
                    }

                    hideTop = false
                    hideBottom = false
                    topHeight = cardHeight + newPartition
                    let oldPartition = partition
                    partition = newPartition
                    notchPartition = snapPartition(for: notchIndex(for: newPartition))

                    if (oldPartition < notchPartition && notchPartition < partition) ||
                        (oldPartition > notchPartition && notchPartition > partition) {
                        rigidImpact.impactOccurred(intensity: 0.5)
                    }
                }
            }
            .onEnded { value in
                if value.translation.height < 2, initialMinimal {
                    let expandingFromCollapsedTop = initialTop
                    let targetSplit = expandingFromCollapsedTop
                        ? collapsedTopTapDetent
                        : collapsedTapDetent
                    withTransaction(transaction) {
                        hideTop = false
                        hideBottom = false
                        overscroll = 0
                        translationBeforeOverscroll = 0
                        applyDetent(targetSplit)
                    }
                    initialPartition = nil
                    initialMinimal = false
                    initialTop = false
                    detent = targetSplit
                    return
                }

                let translation = (initialPartition ?? 0) + value.translation.height
                let minimalAdjustment = (initialMinimal ? (initialTop ? 8 - lil : lil - 8 - bottomExtraOffset) : 0)
                var newPartition = translation + minimalAdjustment
                var newDetent: SplitDetent

                if newPartition < -cardHeight + lil2 {
                    newPartition = lil - cardHeight
                    newDetent = .bottomFull   // top fully collapsed
                } else if newPartition < -cardHeight + lil3 {
                    newPartition = lil3 - cardHeight
                    newDetent = .fraction(0)
                } else if newPartition > cardHeight - lil2 {
                    newPartition = cardHeight - lil
                    newDetent = .topFull
                } else if newPartition > cardHeight - lil3 {
                    newPartition = cardHeight - lil3
                    newDetent = .fraction(1)
                } else {
                    let notch = notchIndex(for: newPartition)
                    newDetent = detentForNotch(notch)
                    newPartition = snapPartition(for: notch)
                }

                withTransaction(transaction) {
                    if initialMinimal && (hideTop || hideBottom) {
                        overscroll = 0
                        return
                    }
                    partition = newPartition
                    topHeight = cardHeight + newPartition
                    if overscroll < -20 {
                        hideTop = false
                        hideBottom = true
                        newDetent = .topFull
                        partition = -(cardHeight - lil)
                        mediumImpact.impactOccurred(intensity: 0.6)
                    } else if overscroll > 20 {
                        hideTop = true
                        hideBottom = false
                        newDetent = .bottomFull
                        partition = cardHeight - lil
                        mediumImpact.impactOccurred(intensity: 0.6)
                    } else {
                        hideTop = false
                        hideBottom = false
                        rigidImpact.impactOccurred(intensity: 0.6)
                    }
                    overscroll = 0
                    translationBeforeOverscroll = 0
                }

                initialPartition = nil
                initialMinimal = hideTop || hideBottom
                initialTop = false
                detent = newDetent
            }
    }

    /// Detent when user taps the collapsed pill (bottom was collapsed → expand to 50/50).
    private var collapsedTapDetent: SplitDetent = .footnotesExpanded

    /// Detent when user taps the collapsed pill (top was collapsed → expand to 50/50).
    private var collapsedTopTapDetent: SplitDetent = .footnotesExpanded

    // MARK: - Body

    public var body: some View {
        let isMinimalPill: Bool = hideTop || hideBottom

        ZStack {
            // ── Panes ──
            VStack(spacing: spacing) {
                if !hideTop {
                    TopWrapper(
                        minimise: min(lil3, topHeight) / lil,
                        overscroll: overscroll,
                        isFull: hideBottom,
                        bgColor: bgColor,
                        content: topView,
                        overlay: {
                            Text(topTitle)
                                .padding(.horizontal)
                                .fontWeight(.semibold)
                        }
                    )
                    .frame(height: hideBottom ? nil : topHeight + overscroll / 5)
                    .transaction(value: hideBottom, { t in
                        t.animation = didSetInitialSplit ? .smooth(duration: 0.4) : .none
                    })
                    .transition(.offset(y: -topHeight - (partition > 0 ? 300 : 200)))
                    .zIndex(1)
                }
                if !hideBottom {
                    BottomWrapper(
                        minimise: 1 - max(0, partition - cardHeight + lil3) / lil,
                        overscroll: overscroll,
                        isFull: hideTop,
                        bgColor: bgColor,
                        content: bottomView,
                        overlay: {
                            Text(bottomTitle)
                                .padding(.horizontal)
                                .fontWeight(.semibold)
                        }
                    )
                    .transaction(value: hideTop, { t in
                        t.animation = didSetInitialSplit ? .smooth(duration: 0.4) : .none
                    })
                    .transition(.offset(y: -partition + range + (partition < 0 ? 300 : 200)))
                    .zIndex(1)
                }
            }
            .animation(.smooth(duration: 0.45), value: hideTop)
            .animation(.smooth(duration: 0.45), value: hideBottom)
            .zIndex(1)

            // ── Background dimming (bottom pane expanded) ──
            if !hideBottom && !hideTop && partition > 0 {
                Color.black.opacity(0.3 * (partition / range))
                    .ignoresSafeArea()
                    .animation(.smooth(duration: 0.4), value: partition)
                    .zIndex(2)
                    .allowsHitTesting(false)
            }

            // ── Handle pill background (black gap) ──
            HStack(spacing: 8) {
                Spacer()
                    .frame(width: 0)  // placeholder for leading accessories

                Text(isMinimalPill ? (hideTop ? topTitle : bottomTitle) : "")
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: isMinimalPill ? 220 : .infinity)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 8)
                    .opacity(0)
                    .foregroundStyle(.primary)

                Spacer()
                    .frame(width: 0)  // placeholder for trailing accessories
            }
            .padding(.horizontal, 12)
            .frame(height: isMinimalPill ? 44 : spacing)
            .frame(maxWidth: isMinimalPill ? nil : .infinity)
            .background(
                Capsule().fill(
                    isMinimalPill
                        ? Color(.systemGray6)
                        : Color(.separator).opacity(0.3)
                )
            )
            .offset(y: handleOffsetY)
            .zIndex(10)

            // ── Handle pill content ──
            HStack(spacing: 8) {
                // Invisible width-anchor for title in collapsed mode
                Text(isMinimalPill ? (hideTop ? topTitle : bottomTitle) : "")
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 220)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 8)
                    .opacity(0)
                    .frame(maxWidth: isMinimalPill ? nil : .infinity)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, isMinimalPill ? 12 : 24 + abs(overscroll / 20))
            .frame(height: isMinimalPill ? 44 : spacing)
            .frame(maxWidth: .infinity, alignment: .center)
            .contentShape(.rect)
            .offset(y: handleOffsetY)
            .gesture(bossGesture)
            .zIndex(11)

            // ── Grabber nub ──
            ZStack {
                Capsule()
                    .fill(.secondary.opacity(0.4))
                    .frame(width: 56, height: 5)
                    .transaction({ t in
                        t.animation = .easeInOut(duration: 0.3)
                    }, body: { $0.scaleEffect(isDragging ? 0.9 : 1) })
                    .blur(radius: isMinimalPill ? 8 : 0)
                    .opacity(isMinimalPill ? 0 : 1)

                // Collapsed pill title
                Text(isMinimalPill ? (hideTop ? topTitle : bottomTitle) : "")
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 220)
                    .fixedSize(horizontal: true, vertical: false)
                    .scaleEffect(isMinimalPill ? 1 : 0.9)
                    .blur(radius: isMinimalPill ? 0 : 12)
                    .opacity(isMinimalPill ? 1 : 0)
                    .foregroundStyle(.primary)
            }
            .offset(y: handleOffsetY)
            .zIndex(12)
            .allowsHitTesting(false)
        }
        .background(Color(.systemBackground))
        .onAppear {
            applyDetent(detent)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                didSetInitialSplit = true
            }
        }
        .onChange(of: detent) { _, newValue in
            var t = transaction
            t.animation = .smooth(duration: 0.5)
            withTransaction(t) {
                applyDetent(newValue)
            }
        }
    }

    // MARK: - Helpers

    private var handleOffsetY: CGFloat {
        (hideTop ? -lil + 8 : hideBottom ? lil - 8 - bottomExtraOffset : 0)
            + (partition + overscroll / (hideTop || hideBottom ? 1 : 5))
    }

    /// Map a partition offset to the nearest notch index (0, 1, or 2).
    private func notchIndex(for partition: CGFloat) -> Int {
        let clamped = min(range, max(-range, partition))
        let progress = (clamped + range) / (range * 2)  // 0…1
        return Int(round(progress * CGFloat(notches)))
    }

    /// Partition offset for a given notch index.
    private func snapPartition(for notch: Int) -> CGFloat {
        let p = CGFloat(notch) / CGFloat(notches) * range * 2 - range
        return p
    }

    private func detentForNotch(_ notch: Int) -> SplitDetent {
        switch notch {
        case 0:  return .footnotesFull      // 4/6 top
        case 1:  return .footnotesExpanded  // 5/6 top
        default: return .topFull            // full top / collapsed
        }
    }

    /// Apply a detent's target partition + visibility.
    private func applyDetent(_ detent: SplitDetent) {
        hideTop = false
        hideBottom = false
        switch detent {
        case .topFull:
            hideBottom = true
            partition = cardHeight - lil
        case .bottomFull:
            hideTop = true
            partition = -cardHeight + lil
        case .footnotesExpanded:
            let idx = 1
            partition = snapPartition(for: idx)
        case .footnotesFull:
            let idx = 0
            partition = snapPartition(for: idx)
        case .fraction(let value):
            if value <= 0 {
                hideTop = true
                partition = -cardHeight + lil
            } else if value >= 1 {
                hideBottom = true
                partition = cardHeight - lil
            } else {
                let notch = Int(round(CGFloat(notches) * value))
                partition = snapPartition(for: notch)
            }
        }
        topHeight = cardHeight + partition
    }

    // MARK: - Init

    /// Creates a VerticalSplit with a top and bottom view.
    /// - Parameters:
    ///   - detent: Binding to the current detent.
    ///   - topTitle: Title shown when the top pane is collapsed.
    ///   - bottomTitle: Title shown when the bottom pane is collapsed.
    ///   - topView: Content for the top pane.
    ///   - bottomView: Content for the bottom pane.
    public init(
        detent: Binding<SplitDetent> = .constant(.footnotesExpanded),
        topTitle: String,
        bottomTitle: String,
        @ViewBuilder topView: @escaping () -> TopView,
        @ViewBuilder bottomView: @escaping () -> BottomView
    ) {
        self._detent = detent
        self.topTitle = topTitle
        self.bottomTitle = bottomTitle
        self.topView = topView
        self.bottomView = bottomView
    }
}
