import AVKit
import SwiftUI

func mergeScreenBackgroundFillPatch(
  _ fill: ScreenBackgroundFill,
  _ patch: ScreenBackgroundFillPatch
) -> ScreenBackgroundFill {
  var next = fill
  if let color = patch.color { next.color = color }
  if let fit = patch.fit { next.fit = fit }
  if patch.opacity != nil { next.opacity = patch.opacity }
  if let scrim = patch.scrim { next.scrim = scrim }
  if patch.loop != nil { next.loop = patch.loop }
  if patch.autoPlay != nil { next.autoPlay = patch.autoPlay }
  if let triggerLayerId = patch.triggerLayerId { next.triggerLayerId = triggerLayerId }
  if let onComplete = patch.onComplete { next.onComplete = onComplete }
  if patch.audioEnabled != nil { next.audioEnabled = patch.audioEnabled }
  return next
}

func resolveScreenContainerStyleAtWidth(
  _ base: ScreenContainerStyle?,
  _ breakpoints: ScreenContainerStyleBreakpoints?,
  width: Double
) -> ScreenContainerStyle? {
  var acc = base
  for key in activeBreakpointKeys(width: width) {
    let patch: ScreenContainerBreakpointPatch? = {
      switch key {
      case "sm": return breakpoints?.sm
      case "md": return breakpoints?.md
      case "lg": return breakpoints?.lg
      case "xl": return breakpoints?.xl
      case "2xl": return breakpoints?.xl2
      default: return nil
      }
    }()
    guard let patch else { continue }
    if acc == nil { acc = ScreenContainerStyle() }
    if let padding = patch.padding { acc?.padding = padding }
    if let margin = patch.margin { acc?.margin = margin }
    if let insetSafeArea = patch.insetSafeArea { acc?.insetSafeArea = insetSafeArea }
    if let backgroundFillPatch = patch.backgroundFillPatch, let fill = acc?.backgroundFill {
      acc?.backgroundFill = mergeScreenBackgroundFillPatch(fill, backgroundFillPatch)
    }
  }
  return acc
}

func resolveScreenBackgroundFillAtWidth(
  _ screen: Screen,
  width: Double
) -> ScreenBackgroundFill? {
  guard var fill = screen.containerStyle?.backgroundFill else { return nil }
  for key in activeBreakpointKeys(width: width) {
    let bpPatch: ScreenContainerBreakpointPatch? = {
      switch key {
      case "sm": return screen.containerStyleBreakpoints?.sm
      case "md": return screen.containerStyleBreakpoints?.md
      case "lg": return screen.containerStyleBreakpoints?.lg
      case "xl": return screen.containerStyleBreakpoints?.xl
      case "2xl": return screen.containerStyleBreakpoints?.xl2
      default: return nil
      }
    }()
    guard let patch = bpPatch?.backgroundFillPatch else { continue }
    fill = mergeScreenBackgroundFillPatch(fill, patch)
  }
  return fill
}

private func scrimColor(
  _ scrim: ScreenBackgroundScrim?,
  theme: Theme?,
  branding: Branding?,
  mode: ThemeMode
) -> Color? {
  guard scrim?.color != nil || scrim?.opacity != nil else { return nil }
  let raw = resolveThemedColorString(scrim?.color, theme: theme, mode: mode) ?? "rgba(0,0,0,0.45)"
  let alpha = scrim?.opacity ?? 0.45
  if let solid = colorFromCssString(raw) {
    return solid.opacity(alpha)
  }
  return Color.black.opacity(alpha)
}

struct ScreenShellBackgroundStack: View {
  var fill: ScreenBackgroundFill
  var theme: Theme?
  var branding: Branding?
  var mode: ThemeMode
  var mediaMap: [String: URL]
  var screenId: String
  var interactive: Bool
  var onRespond: (StepResponse) -> Void
  @EnvironmentObject private var mediaPlayback: MediaPlaybackCoordinator

  var body: some View {
    ZStack {
      switch fill.kind {
      case .color:
        let resolved = resolveSurfaceFill(fill.color, theme: theme, branding: branding, mode: mode)
        screenShellBackdropView(resolved)
          .opacity(fill.opacity ?? 1)
      case .image:
        if let mediaId = fill.media?.mediaAssetId, let url = mediaMap[mediaId] {
          AsyncImage(url: url) { phase in
            if case .success(let image) = phase {
              image
                .resizable()
                .aspectRatio(contentMode: contentMode(fill.fit))
                .opacity(fill.opacity ?? 1)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        if let scrim = scrimColor(fill.scrim, theme: theme, branding: branding, mode: mode) {
          scrim.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      case .video:
        if let mediaId = fill.media?.mediaAssetId, let url = mediaMap[mediaId] {
          ScreenShellVideoBackground(
            url: url,
            fill: fill,
            screenId: screenId,
            interactive: interactive,
            onRespond: onRespond
          )
          .environmentObject(mediaPlayback)
        }
        if let scrim = scrimColor(fill.scrim, theme: theme, branding: branding, mode: mode) {
          scrim.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func contentMode(_ fit: String?) -> ContentMode {
    if fit == "contain" { return .fit }
    return .fill
  }
}

private struct ScreenShellVideoBackground: View {
  var url: URL
  var fill: ScreenBackgroundFill
  var screenId: String
  var interactive: Bool
  var onRespond: (StepResponse) -> Void
  @EnvironmentObject private var mediaPlayback: MediaPlaybackCoordinator
  @State private var player: AVPlayer?

  var body: some View {
    VideoPlayer(player: player)
      .disabled(true)
      .aspectRatio(contentMode: fill.fit == "contain" ? .fit : .fill)
      .opacity(fill.opacity ?? 1)
      .onAppear {
        let p = AVPlayer(url: url)
        p.isMuted = fill.audioEnabled != true
        p.actionAtItemEnd = fill.loop == false ? .pause : .none
        player = p
        let playbackId = screenBackgroundPlaybackId(screenId: screenId)
        mediaPlayback.register(layerId: playbackId) {
          p.seek(to: .zero)
          p.play()
        }
        if mediaAutoPlayOnMount(autoPlay: fill.autoPlay) {
          p.play()
        }
      }
      .onDisappear {
        player?.pause()
        mediaPlayback.unregister(layerId: screenBackgroundPlaybackId(screenId: screenId))
      }
  }
}
