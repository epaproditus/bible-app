//
//  VerticalSplit.swift
//  VerticalSplit
//
//  A simplified draggable-divider container adapted from Doit's
//  VerticalSplit component. Provides 3 snap detents for a
//  top/bottom pane layout.
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

/// Three snap positions (0, 1, 2) mapped to the three detents in order.
private let notchCount: Int = 2  // 0-based → 3 positions

/// Haptic generators (lazy to avoid early allocation).
private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
private let rigidHaptic = UIImpactFeedbackGenerator(style: .rigid)

// MARK: - VerticalSplit

public struct VerticalSplit<TopView: View, BottomView: View>: View {

    @ViewBuilder var topView: () -> TopView
    @ViewBuilder var bottomView: () -> BottomView

    let topTitle: String
    let bottomTitle: String

    @Binding var detent: SplitDetent

    /// Background tint for both pane surfaces.
    var bgColor: Color = Color(.systemBackground)
    /// Handle/pill foreground colour.
    var handleFg: Color = .primary

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

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($isDragging) { _, s, _ in s = true }
            .onChanged { value in
                if initialPartition == nil {
                    initialPartition = partition
                    if hideTop || hideBottom {
                        rigidHaptic.impactOccurred(intensity: 0.6)
                    }
                }

                withTransaction(transaction) {
                    let translation = (initialPartition ?? 0) + value.translation.height
                    let newPartition = min(cardHeight - lil,
                                           max(-cardHeight + lil, translation))

                    // Overscroll buffer for collapsing
                    if translation < -cardHeight + lil {
                        if translationBeforeOverscroll == 0 {
                            translationBeforeOverscroll = translation
                            rigidHaptic.impactOccurred(intensity: 0.8)
                        }
                        overscroll = (translation - translationBeforeOverscroll) * 0.75
                    } else if translation > cardHeight - lil {
                        if translationBeforeOverscroll == 0 {
                            translationBeforeOverscroll = translation
                            rigidHaptic.impactOccurred(intensity: 0.8)
                        }
                        overscroll = (translation - translationBeforeOverscroll) * 0.75
                    } else {
                        translationBeforeOverscroll = 0
                        overscroll = 0
                    }

                    hideTop = false
                    hideBottom = false
                    topHeight = cardHeight + newPartition
                    let old = partition
                    partition = newPartition
                    notchPartition = snapPartition(for: notchIndex(for: newPartition))

                    if (old < notchPartition && notchPartition < partition) ||
                       (old > notchPartition && notchPartition > partition) {
                        rigidHaptic.impactOccurred(intensity: 0.5)
                    }
                }
            }
            .onEnded { value in
                let translation = (initialPartition ?? 0) + value.translation.height
                var newPartition: CGFloat
                var newDetent: SplitDetent

                // Collapse zones (near edges)
                if translation < -cardHeight + lil / 2 {
                    newPartition = -(cardHeight - lil)
                    newDetent = .topFull
                    hideTop = false
                    hideBottom = true
                } else if translation > cardHeight - lil / 2 {
                    newPartition = cardHeight - lil
                    newDetent = .topFull
                    hideTop = true
                    hideBottom = false
                } else {
                    // Snap to nearest notch
                    let idx = notchIndex(for: translation)
                    newPartition = snapPartition(for: idx)
                    newDetent = detentForNotch(idx)
                    hideTop = false
                    hideBottom = false
                }

                // Overscroll → full-screen collapse
                withTransaction(transaction) {
                    if overscroll < -20 {
                        hideTop = false
                        hideBottom = true
                        newDetent = .topFull
                        newPartition = -(cardHeight - lil)
                        rigidHaptic.impactOccurred(intensity: 0.6)
                    } else if overscroll > 20 {
                        hideTop = true
                        hideBottom = false
                        newDetent = .topFull
                        newPartition = cardHeight - lil
                        rigidHaptic.impactOccurred(intensity: 0.6)
                    } else {
                        partition = newPartition
                        topHeight = cardHeight + newPartition
                        rigidHaptic.impactOccurred(intensity: 0.6)
                    }

                    overscroll = 0
                    translationBeforeOverscroll = 0
                }

                initialPartition = nil
                detent = newDetent
            }
    }

    // MARK: - Body

    public var body: some View {
        let isMinimal = hideTop || hideBottom

        ZStack {
            // ── Panes ──
            VStack(spacing: spacing) {
                if !hideTop {
                    topView()
                        .frame(height: topHeight)
                        .clipped()
                        .transition(.offset(y: -topHeight - 300))
                }
                if !hideBottom {
                    bottomView()
                        .frame(maxHeight: hideTop ? .infinity : cardHeight - partition)
                        .clipped()
                        .transition(.offset(y: partition + range + (partition < 0 ? 300 : 200)))
                }
            }
            .animation(.smooth(duration: 0.45), value: hideTop)
            .animation(.smooth(duration: 0.45), value: hideBottom)
            .zIndex(1)

            // ── Drag-pill background track ──
            Capsule()
                .fill(bgColor)
                .frame(height: spacing)
                .frame(maxWidth: .infinity)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                .overlay {
                    // Grabber nub
                    Capsule()
                        .fill(.secondary.opacity(0.5))
                        .frame(width: 48, height: 5)
                }
                .offset(y: handleOffsetY)
                .gesture(dragGesture)
                .zIndex(10)

            // ── Collapsed title pill ──
            if isMinimal {
                HStack(spacing: 8) {
                    Text(hideTop ? topTitle : bottomTitle)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(handleFg)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background {
                    Capsule().fill(.regularMaterial)
                }
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                .offset(y: handleOffsetY)
                .onTapGesture {
                    // Tap collapsed pill → go to .footnotesExpanded
                    withTransaction(transaction) {
                        detent = .footnotesExpanded
                        applyDetent(.footnotesExpanded)
                    }
                }
                .zIndex(11)
            }
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
        (hideTop ? -lil + 8 : hideBottom ? lil - 8 : 0)
            + (partition + overscroll / (hideTop || hideBottom ? 1 : 5))
    }

    /// Map a partition offset to the nearest notch index (0, 1, or 2).
    private func notchIndex(for partition: CGFloat) -> Int {
        let clamped = min(range, max(-range, partition))
        let progress = (clamped + range) / (range * 2) // 0…1
        return Int(round(progress * CGFloat(notchCount)))
    }

    /// Partition offset for a given notch index.
    private func snapPartition(for notch: Int) -> CGFloat {
        let p = CGFloat(notch) / CGFloat(notchCount) * range * 2 - range
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
        case .footnotesExpanded:
            let idx = 1
            partition = snapPartition(for: idx)
        case .footnotesFull:
            let idx = 0
            partition = snapPartition(for: idx)
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

// MARK: - Modifiers

public extension VerticalSplit {
    /// Sets the background colour applied to the track / pane chrome.
    func backgroundColor(_ color: Color) -> Self {
        var copy = self
        copy.bgColor = color
        return copy
    }

    /// Sets the foreground colour for the collapsed pill text.
    func handleForegroundColor(_ color: Color) -> Self {
        var copy = self
        copy.handleFg = color
        return copy
    }
}
