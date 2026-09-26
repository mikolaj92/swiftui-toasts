import SwiftUI
#if os(iOS)
    import UIKit
#endif

/// Owns the toast queue and the island animation. Installed by
/// ``View/dynamicIslandToasts(expanded:compact:pause:)`` and read from the
/// environment anywhere below that modifier.
@MainActor
@Observable
public final class IslandToastCenter {
    private(set) var queue = IslandToastQueue()
    var safeAreaTop: CGFloat = 0
    var hasIslandHardware = false
    var animatesChanges = true

    @ObservationIgnored private let expandedHold: Duration
    @ObservationIgnored private let compactHold: Duration
    @ObservationIgnored private let pause: Duration
    @ObservationIgnored private var isPlaying = false

    var presentation: IslandPresentation { queue.presentation }
    var current: DynamicIslandToast? { queue.current }

    init(
        expandedHold: Duration,
        compactHold: Duration,
        pause: Duration
    ) {
        self.expandedHold = expandedHold
        self.compactHold = compactHold
        self.pause = pause
    }

    /// Queues a toast. If nothing is on screen, it expands immediately.
    /// Later messages wait until the current one folds away and the pause ends.
    public func show(_ toast: DynamicIslandToast) {
        let system = IslandToastLivePresenter.isEnabled
        if !isPlaying, !system {
            animatesChanges = false
        }
        guard queue.receive(toast, showsChrome: !system) == .begin, !isPlaying else { return }
        isPlaying = true
        Task { try? await play() }
    }

    public func show(
        title: String,
        message: String = "",
        symbolName: String = "checkmark.seal.fill",
        tone: IslandToastTone = .success,
        iconURL: URL? = nil
    ) {
        show(
            DynamicIslandToast(
                title: title,
                message: message,
                symbolName: symbolName,
                tone: tone,
                iconURL: iconURL
            )
        )
    }

    func noteScreen(safeAreaTop: CGFloat, hasIslandHardware: Bool) {
        if self.safeAreaTop != safeAreaTop {
            self.safeAreaTop = safeAreaTop
        }
        if self.hasIslandHardware != hasIslandHardware {
            self.hasIslandHardware = hasIslandHardware
        }
    }

    /// One pass over the queue. A system Live Activity stays up for the expanded
    /// hold, then ends. Our own card grows, holds, folds, and pauses. Sleep
    /// throws when the task is cancelled, which ends the pass.
    private func play() async throws {
        defer {
            isPlaying = false
            Task { await IslandToastLivePresenter.dismiss() }
        }
        while true {
            if let toast = queue.current {
                IslandToastFeedback.play(toast.tone)
            }
            if IslandToastLivePresenter.isEnabled,
               let toast = queue.current,
               await IslandToastLivePresenter.present(toast) {
                queue.hideChromeForSystem()
                try await Task.sleep(for: expandedHold)
                await IslandToastLivePresenter.dismiss()
                try await Task.sleep(for: pause)
                guard queue.finishPause(showsChrome: !IslandToastLivePresenter.isEnabled) == .begin else {
                    guard queue.current != nil else { return }
                    continue
                }
                continue
            }

            #if os(tvOS) || os(macOS)
                if queue.presentation != .collapsed {
                    animatesChanges = false
                    guard queue.beginChrome() == .begin else { return }
                }
                try await Task.sleep(for: .milliseconds(32))
                animatesChanges = true
                guard queue.expand() == .holdExpanded else { return }
                try await Task.sleep(for: expandedHold)
                guard queue.dismiss() == .pause else { return }
                try await Task.sleep(for: .milliseconds(350))
                try await Task.sleep(for: pause)
                animatesChanges = false
                guard queue.finishPause(showsChrome: !IslandToastLivePresenter.isEnabled) == .begin else {
                    guard queue.current != nil else { return }
                    continue
                }
                continue
            #endif

            if queue.presentation != .collapsed {
                animatesChanges = false
                guard queue.beginChrome() == .begin else { return }
            }
            try await Task.sleep(for: .milliseconds(32))
            animatesChanges = true
            guard queue.expand() == .holdExpanded else { return }

            try await Task.sleep(for: expandedHold)
            guard queue.fold() == .holdCompact else { return }

            try await Task.sleep(for: compactHold)
            guard queue.rest() == .pause else { return }

            try await Task.sleep(for: pause)
            animatesChanges = false
            guard queue.finishPause(showsChrome: !IslandToastLivePresenter.isEnabled) == .begin else {
                guard queue.current != nil else { return }
                continue
            }
        }
    }
}

enum IslandToastFeedback {
    static func play(_ tone: IslandToastTone) {
        #if os(iOS)
            switch tone {
            case .success:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .failure:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            case .neutral:
                break
            }
        #endif
    }
}
