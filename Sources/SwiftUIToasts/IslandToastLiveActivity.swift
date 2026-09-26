#if os(iOS)
    import ActivityKit
    import SwiftUI
    import WidgetKit

    /// Payload for the system Live Activity. The app's widget extension must
    /// include ``IslandToastActivity`` and `NSSupportsLiveActivities` must be
    /// true, otherwise the request fails and the in-app toast is used.
    public struct IslandToastAttributes: ActivityAttributes, Sendable {
        public struct ContentState: Codable, Hashable, Sendable {
            public var title: String
            public var message: String
            public var symbolName: String
            public var tone: String
        }

        public var toastID: String

        public init(toastID: String) {
            self.toastID = toastID
        }
    }

    /// Live Activity the host widget bundle has to return.
    ///
    /// ```swift
    /// @main
    /// struct ToastsBundle: WidgetBundle {
    ///     var body: some Widget {
    ///         IslandToastActivity()
    ///     }
    /// }
    /// ```
    public struct IslandToastActivity: Widget {
        public init() {}

        public var body: some WidgetConfiguration {
            ActivityConfiguration(for: IslandToastAttributes.self) { context in
                IslandToastActivityCard(state: context.state)
            } dynamicIsland: { context in
                DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) {
                        IslandToastActivitySymbol(state: context.state)
                    }
                    DynamicIslandExpandedRegion(.center) {
                        IslandToastActivityText(state: context.state)
                    }
                } compactLeading: {
                    IslandToastActivitySymbol(state: context.state)
                } compactTrailing: {
                    Text(context.state.title)
                        .lineLimit(1)
                } minimal: {
                    IslandToastActivitySymbol(state: context.state)
                }
            }
        }
    }

    struct IslandToastActivityCard: View {
        var state: IslandToastAttributes.ContentState

        var body: some View {
            HStack(spacing: 10) {
                IslandToastActivitySymbol(state: state)
                IslandToastActivityText(state: state)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    struct IslandToastActivityText: View {
        var state: IslandToastAttributes.ContentState

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                if !state.message.isEmpty {
                    Text(state.message)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    struct IslandToastActivitySymbol: View {
        var state: IslandToastAttributes.ContentState

        var body: some View {
            Image(systemName: state.symbolName)
                .font(.system(size: 28))
                .foregroundStyle(.white, IslandToastLiveColor.color(for: state.tone))
        }
    }

    enum IslandToastLiveColor {
        static func color(for tone: String) -> Color {
            switch tone {
            case IslandToastTone.success.activityName:
                .green
            case IslandToastTone.failure.activityName:
                .red
            default:
                .white.opacity(0.72)
            }
        }
    }

    @MainActor
    enum IslandToastLivePresenter {
        private static var activity: Activity<IslandToastAttributes>?

        static var isEnabled: Bool {
            ActivityAuthorizationInfo().areActivitiesEnabled
        }

        static func present(_ toast: DynamicIslandToast) async -> Bool {
            guard isEnabled else { return false }
            let state = IslandToastAttributes.ContentState(
                title: toast.title,
                message: toast.message,
                symbolName: toast.symbolName,
                tone: toast.tone.activityName
            )
            let content = ActivityContent(state: state, staleDate: nil)
            do {
                activity = try Activity.request(
                    attributes: IslandToastAttributes(toastID: toast.id.uuidString),
                    content: content,
                    pushType: nil,
                    style: .transient
                )
                return true
            } catch {
                activity = nil
                return false
            }
        }

        static func dismiss() async {
            guard let activity else { return }
            self.activity = nil
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    extension Activity: @retroactive @unchecked Sendable where Attributes: Sendable {}
#else
    @MainActor
    enum IslandToastLivePresenter {
        static var isEnabled: Bool { false }

        static func present(_ toast: DynamicIslandToast) async -> Bool { false }

        static func dismiss() async {}
    }
#endif

extension IslandToastTone {
    var activityName: String {
        switch self {
        case .success:
            "success"
        case .failure:
            "failure"
        case .neutral:
            "neutral"
        }
    }
}
