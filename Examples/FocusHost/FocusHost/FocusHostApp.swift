import SwiftUI
import SwiftUIToasts

@main
struct FocusHostApp: App {
    var body: some Scene {
        WindowGroup {
            FocusScreen()
                .dynamicIslandToasts(expanded: .seconds(8))
        }
    }
}

struct FocusScreen: View {
    @Environment(IslandToastCenter.self) private var toasts
    @FocusState private var focused: String?

    var body: some View {
        VStack(spacing: 48) {
            Button("One") {}
                .accessibilityIdentifier("one")
                .focused($focused, equals: "one")
            Button("Two") {}
                .accessibilityIdentifier("two")
                .focused($focused, equals: "two")
        }
        .buttonStyle(.borderedProminent)
        .defaultFocus($focused, "one")
        .onAppear {
            toasts.show(
                title: "Logged in",
                message: "Welcome back",
                tone: .success
            )
        }
    }
}
