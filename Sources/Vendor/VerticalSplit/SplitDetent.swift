//
//  SplitDetent.swift
//  VerticalSplit
//
//  Describes the snap positions for the bible-app draggable divider.
//  Extended with fraction support for the Doit-derived gesture engine.
//

import Foundation

/// Snap detents for the VerticalSplit draggable divider.
///
/// - ``topFull``: Top pane takes the full screen (bottom pane collapsed).
/// - ``footnotesExpanded``: Top pane occupies 5/6 of the screen, bottom 1/6.
/// - ``footnotesFull``: Top pane occupies 4/6 of the screen, bottom 2/6.
/// - ``fraction``: Arbitrary fractional split (0…1 = top fraction).
public enum SplitDetent: Equatable, Sendable {
    /// Top pane fills the screen; bottom pane is collapsed.
    case topFull
    /// Bottom pane fills the screen; top pane is collapsed.
    case bottomFull
    /// Top pane is 5/6, bottom pane is 1/6.
    case footnotesExpanded
    /// Top pane is 4/6, bottom pane is 2/6.
    case footnotesFull
    /// Arbitrary split where `value` is the top pane's fraction (0…1).
    case fraction(CGFloat)

    /// The fractional portion of the screen height given to the top pane.
    public var topFraction: CGFloat {
        switch self {
        case .topFull:              return 1.0
        case .bottomFull:           return 0.0
        case .footnotesExpanded:    return 5.0 / 6.0
        case .footnotesFull:        return 4.0 / 6.0
        case .fraction(let f):      return f
        }
    }
}
