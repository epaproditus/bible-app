//
//  SplitDetent.swift
//  VerticalSplit
//
//  Describes the 3 snap positions for the bible-app draggable divider.
//  Adapted from Doit's VerticalSplit component.
//

import Foundation

/// The 3 snap detents for the VerticalSplit draggable divider.
///
/// - ``topFull``: Top pane takes the full screen (bottom pane collapsed).
/// - ``footnotesExpanded``: Top pane occupies 5/6 of the screen, bottom 1/6.
/// - ``footnotesFull``: Top pane occupies 4/6 of the screen, bottom 2/6.
public enum SplitDetent: Equatable, Sendable {
    /// Top pane fills the screen; bottom pane is collapsed.
    case topFull
    /// Top pane is 5/6, bottom pane is 1/6.
    case footnotesExpanded
    /// Top pane is 4/6, bottom pane is 2/6.
    case footnotesFull

    /// The fractional portion of the screen height given to the top pane.
    public var topFraction: CGFloat {
        switch self {
        case .topFull:              return 1.0
        case .footnotesExpanded:    return 5.0 / 6.0
        case .footnotesFull:        return 4.0 / 6.0
        }
    }
}
