import CoreGraphics
import Foundation

/// Where the toast plate sits. The card and the capsule are the same size on
/// every device. A real Dynamic Island hides the capsule once the symbol rests
/// in the cutout. Everywhere else the capsule stays drawn, under the status bar.
enum IslandChromeStyle: Equatable {
    case dynamicIsland
    case statusBar
    /// Apple TV has no in-app banner API, so the card sits where a system
    /// notification does: the upper trailing corner.
    case banner
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
    var safeAreaTrailing: CGFloat = 0

    /// Measured on the phones in the reference: the cutout is 36pt tall and
    /// starts 11pt below the screen edge when the top safe area is 59.
    static let islandHeight: CGFloat = 36
    static let islandWidth: CGFloat = 120
    static let islandTopInset: CGFloat = 11
    static let referenceSafeAreaTop: CGFloat = 59
    /// Tall enough that the title sits under the cutout, not in it.
    static let expandedHeight: CGFloat = 120
    /// iPad and notch phones have no cutout to clear, so the card hugs the text.
    static let statusBarExpandedHeight: CGFloat = 84
    static let expandedContentGap: CGFloat = 6
    static let expandedHorizontalInset: CGFloat = 10
    static let expandedCornerRadius: CGFloat = 38
    /// Wider than any iPhone. iPad and Mac keep the phone card instead of
    /// stretching it across the screen.
    static let phoneWidthCeiling: CGFloat = 480
    static let regularExpandedWidth: CGFloat = 420
    /// Upper-trailing card on a 1920-point Apple TV canvas.
    static let bannerMaximumWidth: CGFloat = 640
    static let bannerCornerRadius: CGFloat = 30
    static let bannerMinimumTop: CGFloat = 60
    static let bannerMinimumTrailing: CGFloat = 80

    var collapsedSize: CGSize {
        CGSize(width: Self.islandWidth, height: Self.islandHeight)
    }

    /// Defaults match an Apple TV canvas. Mac passes a shorter card and a
    /// smaller inset so the banner stays clear of the title bar.
    var bannerWidthLimit: CGFloat = Self.bannerMaximumWidth
    var bannerTopFloor: CGFloat = Self.bannerMinimumTop
    var bannerTrailingFloor: CGFloat = Self.bannerMinimumTrailing

    var bannerWidth: CGFloat {
        let available = containerWidth - bannerTrailingInset - bannerTrailingFloor
        return min(bannerWidthLimit, max(available, 0))
    }

    var bannerTopInset: CGFloat {
        max(safeAreaTop, bannerTopFloor)
    }

    var bannerTrailingInset: CGFloat {
        max(safeAreaTrailing, bannerTrailingFloor)
    }

    var expandedSize: CGSize {
        if style == .banner {
            return CGSize(width: bannerWidth, height: Self.expandedHeight)
        }
        let edgeToEdge = containerWidth - (Self.expandedHorizontalInset * 2)
        let width = containerWidth > Self.phoneWidthCeiling
            ? min(edgeToEdge, Self.regularExpandedWidth)
            : max(edgeToEdge, collapsedSize.width)
        let height = style == .statusBar ? Self.statusBarExpandedHeight : Self.expandedHeight
        return CGSize(width: width, height: height)
    }

    /// Where the title starts inside the expanded card. On an island phone
    /// that is below the cutout, so no glyph sits in the notch.
    var expandedContentTop: CGFloat {
        switch style {
        case .dynamicIsland:
            max(Self.islandHeight, safeAreaTop - topOffset) + Self.expandedContentGap
        case .statusBar:
            0
        case .banner:
            0
        }
    }

    var topOffset: CGFloat {
        switch style {
        case .dynamicIsland:
            Self.islandTopInset + max(safeAreaTop - Self.referenceSafeAreaTop, 0)
        case .statusBar:
            max(safeAreaTop, Self.islandTopInset)
        case .banner:
            bannerTopInset
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
        if style == .banner {
            return Self.bannerCornerRadius
        }
        switch presentation {
        case .expanded:
            return Self.expandedCornerRadius
        case .idle, .collapsed, .compact:
            return size(for: presentation).height / 2
        }
    }

    /// The black plate covers the status items while expanded. On a real
    /// island it fades after the fold so the hardware cutout shows through.
    /// Devices without that cutout keep the same capsule painted.
    func shapeOpacity(for presentation: IslandPresentation) -> CGFloat {
        switch (style, presentation) {
        case (_, .idle):
            0
        case (.dynamicIsland, .compact), (.banner, .compact):
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
