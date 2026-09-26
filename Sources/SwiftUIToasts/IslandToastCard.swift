import SwiftUI

struct IslandToastOverlay: View {
    var center: IslandToastCenter

    var body: some View {
        let toast = center.current
        let overlay = GeometryReader { proxy in
            IslandToastCard(
                presentation: center.presentation,
                title: toast?.title ?? "",
                message: toast?.message ?? "",
                tone: toast?.tone ?? .neutral,
                symbolName: toast?.symbolName ?? "checkmark.seal.fill",
                iconURL: toast?.iconURL,
                animatesChanges: center.animatesChanges,
                layout: layout(in: proxy)
            )
        }
        .allowsHitTesting(false)
        .focusable(false)
        #if os(macOS)
            overlay
        #else
            overlay.ignoresSafeArea()
        #endif
    }

    private func layout(in proxy: GeometryProxy) -> IslandLayout {
        var layout = IslandLayout(
            containerWidth: proxy.size.width,
            safeAreaTop: max(center.safeAreaTop, proxy.safeAreaInsets.top),
            style: chromeStyle(hasIsland: center.hasIslandHardware),
            safeAreaTrailing: proxy.safeAreaInsets.trailing
        )
        #if os(macOS)
            layout.bannerWidthLimit = 380
            layout.bannerTopFloor = 20
            layout.bannerTrailingFloor = 20
        #endif
        return layout
    }

    private func chromeStyle(hasIsland: Bool) -> IslandChromeStyle {
        #if os(tvOS) || os(macOS)
            return .banner
        #else
            return hasIsland ? .dynamicIsland : .statusBar
        #endif
    }
}

struct IslandToastCard: View {
    var presentation: IslandPresentation
    var title: String
    var message: String
    var tone: IslandToastTone
    var symbolName: String
    var iconURL: URL?
    var animatesChanges: Bool
    var layout: IslandLayout

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if layout.style == .banner {
                banner
            } else {
                island
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
        .accessibilityAddTraits(.isStaticText)
        .onChange(of: presentation) { _, presentation in
            guard presentation == .expanded, !title.isEmpty else { return }
            AccessibilityNotification.Announcement(spoken).post()
        }
    }

    private var banner: some View {
        let shown = presentation == .expanded
        return HStack(alignment: .center, spacing: 22) {
            IslandToastIcon(
                tone: tone,
                symbolName: symbolName,
                iconURL: iconURL,
                wiggles: false,
                side: 72,
                symbolSize: 48
            )
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .frame(width: layout.bannerWidth, alignment: .leading)
        .toastGlass(in: RoundedRectangle(cornerRadius: layout.cornerRadius(for: .expanded), style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
        .offset(x: shown || reduceMotion ? 0 : layout.bannerWidth + layout.bannerTrailingInset)
        .opacity(shown ? 1 : 0)
        .padding(.top, layout.bannerTopInset)
        .padding(.trailing, layout.bannerTrailingInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .animation(bannerMotion, value: presentation)
        .focusable(false)
    }

    @ViewBuilder
    private var island: some View {
        let current = layout.size(for: presentation)
        let scale = layout.scale(for: presentation)

        ZStack {
            RoundedRectangle(
                cornerRadius: layout.cornerRadius(for: presentation),
                style: .continuous
            )
            .fill(Color.black)
            .opacity(layout.shapeOpacity(for: presentation))
            .animation(shapeFade, value: presentation)

            IslandToastLabel(
                title: title,
                message: message,
                showsDetail: layout.detailOpacity(for: presentation) > 0,
                tone: tone,
                symbolName: symbolName,
                iconURL: iconURL,
                contentTopInset: layout.expandedContentTop
            )
            .frame(width: layout.expandedSize.width, height: layout.expandedSize.height)
            .scaleEffect(x: scale.width, y: scale.height)
            .frame(width: current.width, height: current.height)
            .opacity(layout.contentOpacity(for: presentation))
            .geometryGroup()
        }
        .frame(width: current.width, height: current.height)
        .clipShape(
            RoundedRectangle(
                cornerRadius: layout.cornerRadius(for: presentation),
                style: .continuous
            )
        )
        .offset(y: layout.topOffset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(motion, value: presentation)
    }

    private var spoken: String {
        message.isEmpty ? title : "\(title). \(message)"
    }

    private var bannerMotion: Animation? {
        guard animatesChanges else { return nil }
        if reduceMotion {
            return .easeOut(duration: 0.2)
        }
        return .easeInOut(duration: 0.35)
    }

    private var motion: Animation? {
        guard animatesChanges else { return nil }
        if reduceMotion {
            return .easeOut(duration: 0.2)
        }
        return .bouncy(duration: 0.3, extraBounce: 0)
    }

    /// The plate stays opaque while it grows, then disappears just after the
    /// fold so the symbol is left inside the real island.
    private var shapeFade: Animation? {
        guard animatesChanges else { return nil }
        if presentation == .expanded || presentation == .collapsed {
            return .linear(duration: 0.02)
        }
        return .linear(duration: 0.02).delay(0.28)
    }
}

struct IslandToastLabel: View {
    var title: String
    var message: String
    var showsDetail: Bool
    var tone: IslandToastTone
    var symbolName: String
    var iconURL: URL?
    var contentTopInset: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            IslandToastIcon(
                tone: tone,
                symbolName: symbolName,
                iconURL: iconURL,
                wiggles: showsDetail
            )
            IslandToastText(title: title, message: message)
                .opacity(showsDetail ? 1 : 0)
        }
        .padding(.horizontal, 14)
        .padding(.top, showsDetail ? contentTopInset : 0)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: showsDetail && contentTopInset > 0 ? .topLeading : .center
        )
    }
}

struct IslandToastIcon: View {
    var tone: IslandToastTone
    var symbolName: String
    var iconURL: URL?
    var wiggles: Bool
    var side: CGFloat = 50
    var symbolSize: CGFloat = 35

    var body: some View {
        Group {
            if let iconURL {
                AsyncImage(url: iconURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        IslandToastSymbol(name: symbolName, tone: tone, wiggles: wiggles, pointSize: symbolSize)
                    }
                }
            } else {
                IslandToastSymbol(name: symbolName, tone: tone, wiggles: wiggles, pointSize: symbolSize)
            }
        }
        .frame(width: side, height: side)
    }
}

struct IslandToastSymbol: View {
    var name: String
    var tone: IslandToastTone
    var wiggles: Bool
    var pointSize: CGFloat = 35

    var body: some View {
        Image(systemName: name)
            .font(.system(size: pointSize))
            .foregroundStyle(.white, tone.secondary)
            .symbolEffect(.wiggle, options: .default.speed(1.5), value: wiggles)
    }
}

extension View {
    /// Dark liquid glass on OS 26 and later. Older systems keep a dark plate
    /// so the banner does not turn into a bright material.
    @ViewBuilder
    func toastGlass(in shape: some Shape) -> some View {
        if #available(iOS 26, macOS 26, tvOS 26, *) {
            glassEffect(.regular.tint(.black.opacity(0.45)), in: shape)
        } else {
            background(shape.fill(Color.black.opacity(0.78)))
        }
    }
}

struct IslandToastText: View {
    var title: String
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.white.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
