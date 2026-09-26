import CoreGraphics
import Foundation
import Testing

@testable import SwiftUIToasts

@Suite
struct IslandLayoutTests {
    @Test
    func islandAlignsWithTheMeasuredCutout() {
        let layout = IslandLayout(
            containerWidth: 402,
            safeAreaTop: 59,
            style: .dynamicIsland
        )

        #expect(layout.topOffset == 11)
        #expect(layout.expandedContentTop == 54)
        #expect(layout.collapsedSize == CGSize(width: 120, height: 36))
        #expect(layout.expandedSize == CGSize(width: 382, height: 120))
        #expect(layout.cornerRadius(for: .expanded) == 38)
        #expect(layout.cornerRadius(for: .compact) == 18)
    }

    @Test
    func tallerSafeAreaPushesTheIslandDown() {
        let layout = IslandLayout(
            containerWidth: 402,
            safeAreaTop: 62,
            style: .dynamicIsland
        )

        #expect(layout.topOffset == 14)
    }

    @Test
    func devicesWithoutAnIslandUseTheSameCapsule() {
        let notch = IslandLayout(containerWidth: 390, safeAreaTop: 47, style: .statusBar)
        let homeButton = IslandLayout(containerWidth: 375, safeAreaTop: 20, style: .statusBar)
        let island = IslandLayout(containerWidth: 390, safeAreaTop: 59, style: .dynamicIsland)

        #expect(notch.collapsedSize == island.collapsedSize)
        #expect(notch.expandedSize.height == island.expandedSize.height)
        #expect(notch.cornerRadius(for: .expanded) == island.cornerRadius(for: .expanded))
        #expect(notch.topOffset == 47)
        #expect(homeButton.topOffset == 20)
        #expect(notch.shapeOpacity(for: .compact) == 1)
        #expect(homeButton.shapeOpacity(for: .compact) == 1)
    }

    @Test
    func wideScreensKeepThePhoneCardCentered() {
        let ipad = IslandLayout(containerWidth: 1024, safeAreaTop: 24, style: .statusBar)
        let tv = IslandLayout(containerWidth: 1920, safeAreaTop: 60, style: .statusBar)
        let mac = IslandLayout(containerWidth: 1280, safeAreaTop: 0, style: .statusBar)
        let phone = IslandLayout(containerWidth: 402, safeAreaTop: 59, style: .dynamicIsland)

        #expect(ipad.expandedSize == CGSize(width: 420, height: 120))
        #expect(tv.expandedSize == ipad.expandedSize)
        #expect(mac.expandedSize == ipad.expandedSize)
        #expect(ipad.collapsedSize == phone.collapsedSize)
        #expect(ipad.topOffset == 24)
        #expect(tv.topOffset == 60)
        #expect(mac.topOffset == 11)
    }

    @Test
    func compactScaleFitsTheCollapsedPlate() {
        let layout = IslandLayout(
            containerWidth: 402,
            safeAreaTop: 59,
            style: .dynamicIsland
        )
        let scale = layout.scale(for: .compact)

        #expect(abs(layout.expandedSize.width * scale.width - 120) < 0.001)
        #expect(abs(layout.expandedSize.height * scale.height - 36) < 0.001)
        #expect(layout.scale(for: .expanded) == CGSize(width: 1, height: 1))
    }

    @Test
    func islandPlateDisappearsOnceTheSymbolRests() {
        let layout = IslandLayout(
            containerWidth: 402,
            safeAreaTop: 59,
            style: .dynamicIsland
        )

        #expect(layout.shapeOpacity(for: .collapsed) == 1)
        #expect(layout.shapeOpacity(for: .expanded) == 1)
        #expect(layout.shapeOpacity(for: .compact) == 0)
        #expect(layout.shapeOpacity(for: .idle) == 0)
        #expect(layout.contentOpacity(for: .compact) == 1)
        #expect(layout.detailOpacity(for: .expanded) == 1)
        #expect(layout.detailOpacity(for: .compact) == 0)
    }

    @Test
    func statusBarCapsuleStaysVisibleWhenCompact() {
        let layout = IslandLayout(
            containerWidth: 390,
            safeAreaTop: 47,
            style: .statusBar
        )

        #expect(layout.shapeOpacity(for: .compact) == 1)
        #expect(layout.collapsedSize == CGSize(width: 120, height: 36))
    }
}

@Suite
struct IslandToastQueueTests {
    @Test
    func firstMessageStartsImmediatelyAndLaterOnesWait() {
        var queue = IslandToastQueue()
        let first = DynamicIslandToast(title: "One", id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        let second = DynamicIslandToast(title: "Two", id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)

        #expect(queue.receive(first) == .begin)
        #expect(queue.current == first)
        #expect(queue.presentation == .collapsed)

        #expect(queue.receive(second) == .none)
        #expect(queue.current == first)

        #expect(queue.expand() == .holdExpanded)
        #expect(queue.presentation == .expanded)
        #expect(queue.fold() == .holdCompact)
        #expect(queue.presentation == .compact)
        #expect(queue.rest() == .pause)
        #expect(queue.presentation == .idle)

        #expect(queue.finishPause() == .begin)
        #expect(queue.current == second)
        #expect(queue.presentation == .collapsed)
    }

    @Test
    func messageDuringThePausePlaysAfterThePause() {
        var queue = IslandToastQueue()
        let first = DynamicIslandToast(title: "One", id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        let second = DynamicIslandToast(title: "Two", id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)

        _ = queue.receive(first)
        _ = queue.expand()
        _ = queue.fold()
        _ = queue.rest()

        #expect(queue.receive(second) == .none)
        #expect(queue.finishPause() == .begin)
        #expect(queue.current == second)
    }

    @Test
    func pauseWithAnEmptyQueueGoesIdle() {
        var queue = IslandToastQueue()
        let first = DynamicIslandToast(title: "One", id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)

        _ = queue.receive(first)
        _ = queue.expand()
        _ = queue.fold()
        _ = queue.rest()

        #expect(queue.finishPause() == .none)
        #expect(queue.current == nil)
        #expect(queue.presentation == .idle)
    }

    @Test
    func systemActivityHidesOurCapsuleUntilItFails() {
        var queue = IslandToastQueue()
        let toast = DynamicIslandToast(
            title: "One",
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        )

        #expect(queue.receive(toast, showsChrome: false) == .begin)
        #expect(queue.current == toast)
        #expect(queue.presentation == .idle)

        queue.hideChromeForSystem()
        #expect(queue.finishPause(showsChrome: false) == .none)
        #expect(queue.current == nil)
    }
}
