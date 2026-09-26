import CoreGraphics
import Foundation

/// Where the toast plate sits. The card and the capsule are the same size on
/// every device. A real Dynamic Island hides the capsule once the symbol rests
/// in the cutout. Everywhere else the capsule stays drawn, under the status bar.
enum IslandChromeStyle: Equatable {
    case dynamicIsland
    case statusBar
}

enum IslandPresentation: Equatable {
    /// Nothing on screen.
    case idle
    /// Island-sized black plate, aligned with the cutout, before the expand.
    case collapsed
    /// Full card: symbol, title, and message.
    case expanded
    /// Symbol resting in the island after the card folds back.
    case compact
}

struct IslandLayout: Equatable {
    var containerWidth: CGFloat
    var safeAreaTop: CGFloat
    var style: IslandChromeStyle

    /// Measured on the phones in the reference: the cutout is 36pt tall and
    /// starts 11pt below the screen edge when the top safe area is 59.
    static let islandHeight: CGFloat = 36
    static let islandWidth: CGFloat = 120
    static let islandTopInset: CGFloat = 11
    static let referenceSafeAreaTop: CGFloat = 59
    static let expandedHeight: CGFloat = 90
    static let expandedHorizontalInset: CGFloat = 10
    static let expandedCornerRadius: CGFloat = 38
    /// Wider than any iPhone. iPad, Apple TV, and Mac keep the phone card
    /// instead of stretching it across the screen.
    static let phoneWidthCeiling: CGFloat = 480
    static let regularExpandedWidth: CGFloat = 420

    var collapsedSize: CGSize {
        CGSize(width: Self.islandWidth, height: Self.islandHeight)
    }

    var expandedSize: CGSize {
        let edgeToEdge = containerWidth - (Self.expandedHorizontalInset * 2)
        let width = containerWidth > Self.phoneWidthCeiling
            ? min(edgeToEdge, Self.regularExpandedWidth)
            : max(edgeToEdge, collapsedSize.width)
        return CGSize(width: width, height: Self.expandedHeight)
    }

    var topOffset: CGFloat {
        switch style {
        case .dynamicIsland:
            Self.islandTopInset + max(safeAreaTop - Self.referenceSafeAreaTop, 0)
        case .statusBar:
            max(safeAreaTop, Self.islandTopInset)
        }
    }

    func size(for presentation: IslandPresentation) -> CGSize {
        switch presentation {
        case .expanded:
            expandedSize
        case .idle, .collapsed, .compact:
            collapsedSize
        }
    }

    func scale(for presentation: IslandPresentation) -> CGSize {
        let current = size(for: presentation)
        return CGSize(
            width: current.width / expandedSize.width,
            height: current.height / expandedSize.height
        )
    }

    func cornerRadius(for presentation: IslandPresentation) -> CGFloat {
        switch presentation {
        case .expanded:
            Self.expandedCornerRadius
        case .idle, .collapsed, .compact:
            size(for: presentation).height / 2
        }
    }

    /// The black plate covers the status items while expanded. On a real
    /// island it fades after the fold so the hardware cutout shows through.
    /// Devices without that cutout keep the same capsule painted.
    func shapeOpacity(for presentation: IslandPresentation) -> CGFloat {
        switch (style, presentation) {
        case (_, .idle):
            0
        case (.dynamicIsland, .compact):
            0
        case (_, .collapsed), (_, .expanded), (.statusBar, .compact):
            1
        }
    }

    func contentOpacity(for presentation: IslandPresentation) -> CGFloat {
        switch presentation {
        case .idle, .collapsed:
            0
        case .expanded, .compact:
            1
        }
    }

    func detailOpacity(for presentation: IslandPresentation) -> CGFloat {
        presentation == .expanded ? 1 : 0
    }
}
