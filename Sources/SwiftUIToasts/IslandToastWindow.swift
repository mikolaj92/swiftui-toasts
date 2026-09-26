#if canImport(UIKit) && !os(macOS)
    import SwiftUI
    import UIKit

    struct IslandToastBridge: UIViewRepresentable {
        var center: IslandToastCenter

        func makeUIView(context: Context) -> IslandToastAnchor {
            let view = IslandToastAnchor()
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
            view.onWindow = { [weak coordinator = context.coordinator] window in
                coordinator?.attach(to: window, center: center)
            }
            return view
        }

        func updateUIView(_ uiView: IslandToastAnchor, context: Context) {
            if let window = uiView.window {
                context.coordinator.attach(to: window, center: center)
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        @MainActor
        final class Coordinator {
            private var window: PassThroughWindow?
            private var host: UIHostingController<IslandToastOverlay>?

            func attach(to sceneWindow: UIWindow, center: IslandToastCenter) {
                if let scene = sceneWindow.windowScene {
                    install(in: scene, center: center)
                }
                let safeAreaTop = sceneWindow.safeAreaInsets.top
                let hasIsland = UIDevice.current.userInterfaceIdiom == .phone && safeAreaTop >= 59
                center.noteScreen(safeAreaTop: safeAreaTop, hasIslandHardware: hasIsland)
            }

            private func install(in scene: UIWindowScene, center: IslandToastCenter) {
                if host != nil {
                    return
                }
                let host = UIHostingController(rootView: IslandToastOverlay(center: center))
                host.view.backgroundColor = .clear
                let window = PassThroughWindow(windowScene: scene)
                window.backgroundColor = .clear
                #if os(iOS)
                    window.windowLevel = .statusBar + 1
                #else
                    window.windowLevel = .alert + 1
                #endif
                window.isUserInteractionEnabled = false
                window.rootViewController = host
                window.isHidden = false
                self.host = host
                self.window = window
            }
        }
    }

    final class IslandToastAnchor: UIView {
        var onWindow: ((UIWindow) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window else { return }
            onWindow?(window)
        }
    }

    /// Sits above the status bar. Every touch falls through to the app.
    final class PassThroughWindow: UIWindow {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            nil
        }
    }
#endif
