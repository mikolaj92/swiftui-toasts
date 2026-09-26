import Foundation

struct IslandToastQueue: Equatable {
    /// Waiting messages, not counting the one on screen. Extra arrivals are
    /// dropped so a burst cannot pin the island for minutes.
    static let waitingLimit = 10

    private(set) var pending: [DynamicIslandToast] = []
    private(set) var current: DynamicIslandToast?
    private(set) var presentation: IslandPresentation = .idle
    private(set) var coolingDown = false

    mutating func receive(
        _ toast: DynamicIslandToast,
        showsChrome: Bool = true
    ) -> IslandToastCue {
        guard !isDuplicate(toast), pending.count < Self.waitingLimit else { return .none }
        pending.append(toast)
        return promote(showsChrome: showsChrome)
    }

    mutating func expand() -> IslandToastCue {
        guard presentation == .collapsed, current != nil else { return .none }
        presentation = .expanded
        return .holdExpanded
    }

    mutating func fold() -> IslandToastCue {
        guard presentation == .expanded else { return .none }
        presentation = .compact
        return .holdCompact
    }

    /// Leaves the expanded card without the island's compact rest. Used by the
    /// Apple TV banner, which slides away instead of folding into a capsule.
    mutating func dismiss() -> IslandToastCue {
        guard presentation == .expanded else { return .none }
        presentation = .idle
        coolingDown = true
        return .pause
    }

    mutating func rest() -> IslandToastCue {
        guard presentation == .compact else { return .none }
        presentation = .idle
        coolingDown = true
        return .pause
    }

    mutating func finishPause(showsChrome: Bool = true) -> IslandToastCue {
        guard coolingDown else { return .none }
        coolingDown = false
        current = nil
        return promote(showsChrome: showsChrome)
    }

    /// Drops our capsule while a system Live Activity is on screen.
    mutating func hideChromeForSystem() {
        presentation = .idle
        coolingDown = true
    }

    /// Starts our capsule after the system refused the activity.
    mutating func beginChrome() -> IslandToastCue {
        guard current != nil else { return .none }
        presentation = .collapsed
        return .begin
    }

    private func isDuplicate(_ toast: DynamicIslandToast) -> Bool {
        if let current, current.sameMessage(as: toast) { return true }
        return pending.contains { $0.sameMessage(as: toast) }
    }

    private mutating func promote(showsChrome: Bool) -> IslandToastCue {
        guard current == nil, !coolingDown, !pending.isEmpty else { return .none }
        current = pending.removeFirst()
        if showsChrome {
            presentation = .collapsed
        }
        return .begin
    }
}

enum IslandToastCue: Equatable {
    case none
    case begin
    case holdExpanded
    case holdCompact
    case pause
}
