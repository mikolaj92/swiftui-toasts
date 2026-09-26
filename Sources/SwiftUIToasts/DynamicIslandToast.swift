import SwiftUI

/// Visual tone of the leading symbol. Success and failure use a white glyph
/// with a green or red secondary palette color.
public enum IslandToastTone: Hashable, Sendable {
    case success
    case failure
    case neutral

    var secondary: Color {
        switch self {
        case .success:
            .green
        case .failure:
            .red
        case .neutral:
            .white.opacity(0.72)
        }
    }
}

/// One queued toast. The island shows `symbolName`, or `iconURL` when a
/// remote logo is available.
public struct DynamicIslandToast: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var message: String
    public var symbolName: String
    public var tone: IslandToastTone
    public var iconURL: URL?

    public init(
        title: String,
        message: String = "",
        symbolName: String = "checkmark.seal.fill",
        tone: IslandToastTone = .success,
        iconURL: URL? = nil,
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.symbolName = symbolName
        self.tone = tone
        self.iconURL = iconURL
    }
}

extension View {
    /// Installs the toast queue and the Dynamic Island presentation.
    ///
    /// Put this once on the root of a scene. Anywhere below it, send a message
    /// and the queue, timing, and island animation run on their own:
    ///
    /// ```swift
    /// struct AppRoot: View {
    ///     var body: some View {
    ///         HomeView()
    ///             .dynamicIslandToasts()
    ///     }
    /// }
    ///
    /// struct HomeView: View {
    ///     @Environment(IslandToastCenter.self) private var toasts
    ///
    ///     var body: some View {
    ///         Button("Log in") {
    ///             toasts.show(title: "Logged in to TV 2", tone: .success)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// On iPhone, a toast uses the system Live Activity when
    /// `ActivityAuthorizationInfo` says activities are enabled and the app's
    /// widget bundle includes ``IslandToastActivity``. Otherwise, and on iPad,
    /// Mac, and Apple TV, the same card is drawn by this library.
    public func dynamicIslandToasts(
        expanded: Duration = .milliseconds(2200),
        compact: Duration = .milliseconds(1400),
        pause: Duration = .seconds(1)
    ) -> some View {
        modifier(
            DynamicIslandToastsModifier(
                expanded: expanded,
                compact: compact,
                pause: pause
            )
        )
    }
}

struct DynamicIslandToastsModifier: ViewModifier {
    var expanded: Duration
    var compact: Duration
    var pause: Duration

    @State private var center: IslandToastCenter

    init(expanded: Duration, compact: Duration, pause: Duration) {
        self.expanded = expanded
        self.compact = compact
        self.pause = pause
        _center = State(
            initialValue: IslandToastCenter(
                expandedHold: expanded,
                compactHold: compact,
                pause: pause
            )
        )
    }

    func body(content: Content) -> some View {
        #if canImport(UIKit) && !os(macOS)
            content
                .environment(center)
                .background {
                    IslandToastBridge(center: center)
                }
        #else
            content
                .environment(center)
                .overlay(alignment: .top) {
                    IslandToastOverlay(center: center)
                }
        #endif
    }
}
