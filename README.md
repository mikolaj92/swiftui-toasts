# SwiftUIToasts

One modifier, then `show`. The queue, timing, and animation stay inside the library.

On iPhone the toast is a system Live Activity when Live Activities are turned on and the app includes the widget below. Everywhere else, and whenever that request fails, the library draws the same card itself.

The in-app card, on an iPhone 17 Pro. It grows from the island. The title stays under the notch, then the card folds back to the symbol.

![Toast growing from the Dynamic Island](docs/private-toast.gif)

| Expanded from the island | Compact, symbol in the island |
| --- | --- |
| ![Expanded toast growing from the island](docs/private-expanded.png) | ![Compact symbol in the island](docs/private-compact.png) |

## Add the package

```swift
dependencies: [
    .package(url: "https://github.com/mikolaj92/swiftui-toasts", branch: "main"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["SwiftUIToasts"]
    ),
]
```

In an Xcode app: File → Add Package Dependencies → `https://github.com/mikolaj92/swiftui-toasts`.

## Send a toast

Put the modifier on a parent of the views that send messages. Those views read the center from the environment.

```swift
import SwiftUI
import SwiftUIToasts

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .dynamicIslandToasts()
        }
    }
}

struct HomeView: View {
    @Environment(IslandToastCenter.self) private var toasts

    var body: some View {
        Button("Log in") {
            toasts.show(
                title: "Logged in",
                message: "Welcome back",
                tone: .success
            )
        }
    }
}
```

Messages play one at a time. The card stays expanded for 2.2 seconds, folds for 1.4 seconds, then waits 1 second before the next one. Pass different durations to `.dynamicIslandToasts(expanded:compact:pause:)`.

iPad, Mac, and Apple TV use that same card, centered at the top, at phone width.

## System Dynamic Island

This part is optional. Without it, every toast uses the in-app card.

1. In the app target, set `NSSupportsLiveActivities` to `YES`.
2. Add a Widget Extension whose bundle returns ``IslandToastActivity``:

```swift
import SwiftUI
import SwiftUIToasts
import WidgetKit

@main
struct ToastsBundle: WidgetBundle {
    var body: some Widget {
        IslandToastActivity()
    }
}
```

`Examples/ToastDemo` is that setup, ready to open in Xcode. There is no permission prompt. The library only reads whether Live Activities are already enabled, asks the system to present one, and uses the in-app card if the system says no.
