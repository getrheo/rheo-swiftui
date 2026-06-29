import AVKit
import SwiftUI

private func mediaFillsHeight(_ height: LayoutHeight?) -> Bool {
  if case .preset(let preset) = height, preset == "fill" || preset == "full" { return true }
  return false
}

private func mediaLayoutStyle(_ style: ImageStyle?) -> CommonStyle? {
  guard var style = style?.asCommonStyle else { return nil }
  style.width = nil
  style.height = nil
  return style
}

private func fireMediaOnComplete(layer: LottieLayer, ctx: LayerRendererContext) {
  guard layer.loop == false else { return }
  let mode = layer.onComplete?.mode ?? "none"
  guard ctx.interactive, mode == "next" else { return }
  ctx.onRespond(.cta(action: "primary"))
}

private func fireMediaOnComplete(layer: VideoLayer, ctx: LayerRendererContext) {
  guard layer.loop == false else { return }
  let mode = layer.onComplete?.mode ?? "none"
  guard ctx.interactive else { return }
  if mode == "next" {
    ctx.onRespond(.cta(action: "primary"))
  } else if mode == "screen", let screenId = layer.onComplete?.screenId {
    ctx.onRespond(.goToScreen(screenId: screenId))
  }
}

struct ImageLayerView: View {
  var layer: ImageLayer
  var ctx: LayerRendererContext

  var body: some View {
    let resolved = resolveImageStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx)
    let url = layer.media.flatMap { ctx.mediaMap[$0.mediaAssetId] }
    ZStack {
      if let url {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: contentMode(resolved?.fit))
          default:
            placeholder
          }
        }
      } else {
        placeholder
      }
    }
    .frame(
      width: widthPoints(resolved?.width, containerWidth: CGFloat(ctx.previewWidthPx)),
      height: mediaFillsHeight(resolved?.height) ? nil : heightPoints(resolved?.height)
    )
    .frame(maxHeight: mediaFillsHeight(resolved?.height) ? .infinity : nil)
    .clipped()
    .accessibilityLabel(layer.alt ?? "Image")
    .rheoCommonStyle(
      mediaLayoutStyle(resolved),
      ctx: ctx,
      containerWidth: CGFloat(ctx.previewWidthPx)
    )
  }

  private var placeholder: some View {
    RoundedRectangle(cornerRadius: 10)
      .fill(ctx.theme == .dark ? Color(white: 0.1) : Color(white: 0.95))
      .overlay(Text("No media").font(.caption2).foregroundStyle(.secondary))
  }

  private func contentMode(_ fit: String?) -> ContentMode {
    if fit == "contain" { return .fit }
    return .fill
  }
}

struct LottieLayerView: View {
  var layer: LottieLayer
  var ctx: LayerRendererContext
  @EnvironmentObject private var mediaPlayback: MediaPlaybackCoordinator
  @State private var usePlaceholder = false
  @State private var shouldPlay = false
  @State private var completed = false

  var body: some View {
    let resolved = resolveImageStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx)
    let url = layer.media.flatMap { ctx.mediaMap[$0.mediaAssetId] }
    let fit = resolved?.fit ?? "contain"
    let uiContentMode: UIView.ContentMode = fit == "cover" || fit == "fill" ? .scaleAspectFill : .scaleAspectFit
    let autoplay = mediaAutoPlayOnMount(autoPlay: layer.autoPlay)
    ZStack {
      if let url, !usePlaceholder {
        BundledLottieRenderer()
          .lottie(url: url, loop: layer.loop != false, contentMode: uiContentMode)
          .onAppear { usePlaceholder = false }
      } else if url != nil {
        PlaceholderLottieRenderer()
          .lottie(url: url!, loop: layer.loop != false, contentMode: uiContentMode)
      } else {
        Text("No media").font(.caption2).foregroundStyle(.secondary)
      }
    }
    .frame(
      width: widthPoints(resolved?.width, containerWidth: CGFloat(ctx.previewWidthPx)),
      height: mediaFillsHeight(resolved?.height) ? nil : heightPoints(resolved?.height)
    )
    .frame(maxHeight: mediaFillsHeight(resolved?.height) ? .infinity : nil)
    .rheoCommonStyle(
      mediaLayoutStyle(resolved),
      ctx: ctx,
      containerWidth: CGFloat(ctx.previewWidthPx)
    )
    .onAppear {
      completed = false
      shouldPlay = autoplay
      mediaPlayback.register(layerId: layer.id) {
        guard !shouldPlay else { return }
        completed = false
        shouldPlay = true
      }
      if autoplay { shouldPlay = true }
    }
    .onDisappear {
      mediaPlayback.unregister(layerId: layer.id)
    }
    .onChange(of: mediaPlayback.playGeneration) { _ in
      if !autoplay { shouldPlay = true }
    }
    .onChange(of: shouldPlay) { playing in
      if playing, layer.loop == false {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
          guard !completed else { return }
          completed = true
          fireMediaOnComplete(layer: layer, ctx: ctx)
        }
      }
    }
  }
}

struct VideoLayerView: View {
  var layer: VideoLayer
  var ctx: LayerRendererContext
  @EnvironmentObject private var mediaPlayback: MediaPlaybackCoordinator
  @State private var playToken = 0

  var body: some View {
    let resolved = resolveImageStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx)
    let url = layer.media.flatMap { ctx.mediaMap[$0.mediaAssetId] }
    let fit = resolved?.fit ?? "contain"
    let contentMode: ContentMode = fit == "contain" ? .fit : .fill
    let autoplay = mediaAutoPlayOnMount(autoPlay: layer.autoPlay)
    ZStack {
      if let url {
        RheoVideoPlayer(
          url: url,
          loop: layer.loop != false,
          muted: layer.audioEnabled != true,
          autoplay: autoplay,
          playToken: playToken,
          onFinished: {
            fireMediaOnComplete(layer: layer, ctx: ctx)
          }
        )
        .aspectRatio(contentMode: contentMode)
        .onAppear {
          mediaPlayback.register(layerId: layer.id) {
            playToken += 1
          }
          if autoplay { playToken += 1 }
        }
        .onDisappear {
          mediaPlayback.unregister(layerId: layer.id)
        }
        .onChange(of: mediaPlayback.playGeneration) { _ in
          if !autoplay { playToken += 1 }
        }
      } else {
        Text("No media").font(.caption2).foregroundStyle(.secondary)
      }
    }
    .frame(
      width: widthPoints(resolved?.width, containerWidth: CGFloat(ctx.previewWidthPx)),
      height: mediaFillsHeight(resolved?.height) ? nil : heightPoints(resolved?.height)
    )
    .frame(maxHeight: mediaFillsHeight(resolved?.height) ? .infinity : nil)
    .clipped()
    .rheoCommonStyle(
      mediaLayoutStyle(resolved),
      ctx: ctx,
      containerWidth: CGFloat(ctx.previewWidthPx)
    )
  }
}

private struct RheoVideoPlayer: View {
  let url: URL
  let loop: Bool
  let muted: Bool
  let autoplay: Bool
  let playToken: Int
  let onFinished: () -> Void
  @State private var player: AVPlayer?
  @State private var finished = false

  var body: some View {
    VideoPlayer(player: player)
      .allowsHitTesting(false)
      .onAppear {
        finished = false
        let p = AVPlayer(url: url)
        p.isMuted = muted
        player = p
        if autoplay { p.play() }
        guard let item = p.currentItem else { return }
        NotificationCenter.default.addObserver(
          forName: .AVPlayerItemDidPlayToEndTime,
          object: item,
          queue: .main
        ) { _ in
          if loop {
            p.seek(to: .zero)
            p.play()
          } else if !finished {
            finished = true
            onFinished()
          }
        }
      }
      .onChange(of: playToken) { _ in
        guard let p = player else { return }
        if p.rate > 0, p.timeControlStatus == .playing { return }
        finished = false
        p.seek(to: .zero)
        p.play()
      }
      .onChange(of: muted) { value in
        player?.isMuted = value
      }
  }
}

struct IconLayerView: View {
  var layer: IconLayer
  var ctx: LayerRendererContext

  var body: some View {
    let resolved = resolveIconStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx)
    // Glyph fits the box (`min(width, height)`); no `style.size`.
    let size = iconSize(resolved)
    RheoIconRenderer()
      .icon(
        family: layer.family,
        name: layer.iconName,
        size: size,
        color: resolveColor(resolved?.color, theme: ctx.manifest.theme, mode: ctx.theme, fallback: defaultThemedForeground)
      )
      .rheoCommonStyle(resolved?.asCommonStyle, ctx: ctx, containerWidth: CGFloat(ctx.previewWidthPx))
  }

  private func iconSize(_ style: IconStyle?) -> CGFloat {
    let w: CGFloat? = {
      if case .number(let n)? = style?.width { return CGFloat(n) }
      return nil
    }()
    let h: CGFloat? = {
      if case .number(let n)? = style?.height { return CGFloat(n) }
      return nil
    }()
    if let w, let h { return max(8, min(w, h)) }
    if let h { return h }
    if let w { return w }
    return 24
  }
}

extension ImageStyle {
  var asCommonStyle: CommonStyle {
    var style = CommonStyle()
    style.padding = padding
    style.margin = margin
    style.radius = radius
    style.background = background
    style.border = border
    style.shadow = shadow
    style.opacity = opacity
    style.width = width
    style.position = position
    style.inset = inset
    style.zIndex = zIndex
    style.height = height
    return style
  }
}

extension IconStyle {
  var asCommonStyle: CommonStyle {
    var style = CommonStyle()
    style.padding = padding
    style.margin = margin
    style.radius = radius
    style.background = background
    style.border = border
    style.shadow = shadow
    style.opacity = opacity
    style.width = width
    style.position = position
    style.inset = inset
    style.zIndex = zIndex
    style.height = height
    return style
  }
}
