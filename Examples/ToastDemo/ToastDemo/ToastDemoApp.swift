import SwiftUI
import SwiftUIToasts

@main
struct ToastDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoScreen()
                .dynamicIslandToasts()
        }
    }
}

struct DemoScreen: View {
    @Environment(IslandToastCenter.self) private var toasts

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 8) {
                Text("SwiftUI Toasts")
                    .font(.largeTitle.weight(.semibold))
                Text("One modifier. The queue does the rest.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 12) {
                Button("Success") { show(.success) }
                Button("Failure") { show(.failure) }
                Button("Neutral") { show(.neutral) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: playDemoIfNeeded)
    }

    private func show(_ tone: IslandToastTone) {
        switch tone {
        case .success:
            toasts.show(
                title: "Logged in",
                message: "Welcome back",
                symbolName: "checkmark.seal.fill",
                tone: .success
            )
        case .failure:
            toasts.show(
                title: "Couldn't save",
                message: "Check the connection",
                symbolName: "xmark.circle.fill",
                tone: .failure
            )
        case .neutral:
            toasts.show(
                title: "Copied",
                message: "Link is on the clipboard",
                symbolName: "doc.on.doc.fill",
                tone: .neutral
            )
        }
    }

    private func playDemoIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("--demo") else { return }
        Task {
            try? await Task.sleep(for: .seconds(1))
            show(.success)
        }
    }
}
