import SwiftUI

struct ProgressLayerView: View {
  var layer: ProgressLayer
  var ctx: LayerRendererContext

  var body: some View {
    let ratio = flowProgressRatio()
    // Bar height: authored via `style.height` (pt); shared default for sparse manifests.
    let height: CGFloat = {
      if case .number(let n) = layer.style?.height { return CGFloat(n) }
      return LayoutScalarDefaults.progressLinearHeight
    }()
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule().fill(resolveColor(layer.trackColor, theme: ctx.manifest.theme, mode: ctx.theme, fallback: .raw(ctx.theme == .dark ? "#3f3f46" : "#e4e4e7")))
        Capsule().fill(resolveColor(layer.fillColor, theme: ctx.manifest.theme, mode: ctx.theme, fallback: ctx.manifest.theme?.primary ?? .raw(ctx.theme == .dark ? "#fafafa" : "#0a0a0a")))
          .frame(width: geo.size.width * ratio)
      }
    }
    .frame(height: height)
    .rheoCommonStyle(layer.style, ctx: ctx, containerWidth: CGFloat(ctx.previewWidthPx))
  }

  private func flowProgressRatio() -> CGFloat {
    let count = max(1, ctx.manifest.screens.count)
    let idx = ctx.manifest.screens.firstIndex { $0.id == ctx.screen.id } ?? 0
    return CGFloat(min(1, Double(idx + 1) / Double(count)))
  }
}

struct LoaderLayerView: View {
  var layer: LoaderLayer
  var ctx: LayerRendererContext
  @State private var progress = 0.0
  @State private var completedNavigation = false

  private var contentHorizontalAlignment: Alignment {
    switch layer.align {
    case "center": return .center
    case "end": return .trailing
    default: return .leading
    }
  }

  private var trackFill: Color {
    resolveColor(
      layer.trackColor,
      theme: ctx.manifest.theme,
      mode: ctx.theme,
      fallback: .raw(ctx.theme == .dark ? "#3f3f46" : "#e4e4e7")
    )
    .opacity(layer.trackOpacity ?? 1)
  }

  private var barFill: Color {
    resolveColor(
      layer.fillColor,
      theme: ctx.manifest.theme,
      mode: ctx.theme,
      fallback: ctx.manifest.theme?.primary ?? .raw(ctx.theme == .dark ? "#fafafa" : "#0a0a0a")
    )
  }

  var body: some View {
    // Circular size = `style.width` (validated equal to `style.height`); ring
    // thickness = `style.strokeWidth`. Linear bar = `style.height`. Shared
    // defaults apply only when the manifest omits a value.
    let circularSize: CGFloat = {
      if case .number(let n) = layer.style?.width { return CGFloat(n) }
      return LayoutScalarDefaults.loaderCircularSize
    }()
    let strokeW = CGFloat(layer.style?.strokeWidth ?? LayoutScalarDefaults.loaderStrokeWidth)
    let linearHeight: CGFloat = {
      if case .number(let n) = layer.style?.height { return CGFloat(n) }
      return LayoutScalarDefaults.loaderLinearHeight
    }()
    let target = (layer.targetPercent ?? 100) / 100

    Group {
      if layer.variant == "circular" {
        ZStack {
          Circle()
            .stroke(trackFill, lineWidth: strokeW)
            .frame(width: circularSize, height: circularSize)
          Circle()
            .trim(from: 0, to: progress * target)
            .stroke(barFill, style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
            .frame(width: circularSize, height: circularSize)
            .rotationEffect(.degrees(-90))
        }
        .frame(width: circularSize, height: circularSize)
        .accessibilityHidden(true)
      } else {
        GeometryReader { geo in
          ZStack(alignment: .leading) {
            Capsule().fill(trackFill)
            Capsule()
              .fill(barFill)
              .frame(width: geo.size.width * progress * target)
          }
        }
        .frame(height: linearHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loader")
        .accessibilityValue("\(Int(progress * target * 100)) percent")
      }
    }
    .frame(maxWidth: .infinity, alignment: contentHorizontalAlignment)
    .onAppear { runLoaderFillAnimation(target: target) }
    .rheoCommonStyle(layer.style, ctx: ctx, containerWidth: CGFloat(ctx.previewWidthPx))
  }

  private func runLoaderFillAnimation(target: Double) {
    completedNavigation = false
    guard ctx.interactive else {
      progress = 1
      return
    }
    let mode = layer.onComplete?.mode ?? "none"
    guard mode != "none" else {
      progress = 0
      let duration = Double(layer.durationMs ?? 2_000) / 1_000
      let delay = Double(layer.fillDelayMs ?? 0) / 1_000
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        withAnimation(.linear(duration: duration)) {
          progress = target
        }
      }
      return
    }
    progress = 0
    let duration = Double(layer.durationMs ?? 2_000) / 1_000
    let delay = Double(layer.fillDelayMs ?? 0) / 1_000
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      withAnimation(.linear(duration: duration)) {
        progress = target
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
        fireLoaderOnComplete(mode: mode)
      }
    }
  }

  private func fireLoaderOnComplete(mode: String) {
    guard !completedNavigation else { return }
    if findManualSubmitInputLayer(ctx.screen) != nil { return }
    completedNavigation = true
    if mode == "next" {
      ctx.onRespond(.cta(action: "primary"))
    } else if mode == "screen", let id = layer.onComplete?.screenId {
      ctx.onRespond(.goToScreen(screenId: id))
    }
  }
}

struct CounterLayerView: View {
  var layer: CounterLayer
  var ctx: LayerRendererContext
  @State private var displayText: String

  init(layer: CounterLayer, ctx: LayerRendererContext) {
    self.layer = layer
    self.ctx = ctx
    _displayText = State(
      initialValue: formatCounterLayerDisplay(
        layer.startValue,
        displayKind: layer.displayKind,
        decimalPlaces: layer.decimalPlaces,
        timeFormat: layer.timeFormat
      )
    )
  }

  var body: some View {
    let resolved = resolveTextStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx)
    let textFill = resolveSurfaceFill(resolved?.background, theme: ctx.manifest.theme, branding: ctx.branding, mode: ctx.theme)
    let dispOpts = (
      displayKind: layer.displayKind,
      decimalPlaces: layer.decimalPlaces,
      timeFormat: layer.timeFormat
    )
    Text(displayText)
      .font(.system(size: CGFloat(resolved?.fontSize ?? 14), weight: rheoFontWeight(resolved?.fontWeight)))
      .foregroundStyle(resolveColor(resolved?.color, theme: ctx.manifest.theme, mode: ctx.theme, fallback: defaultThemedForeground))
      .task(id: animationTaskKey) {
        await runCounterAnimation(dispOpts: dispOpts)
      }
      .rheoSurfaceBackground(textFill, opacity: resolved?.backgroundOpacity ?? 1)
      .rheoCommonStyle(resolved.map(\.commonStyleWithoutBackground), ctx: ctx, containerWidth: CGFloat(ctx.previewWidthPx))
  }

  private var animationTaskKey: String {
    "\(layer.id)-\(ctx.screen.id)-\(ctx.interactive)"
  }

  @MainActor
  private func runCounterAnimation(
    dispOpts: (displayKind: String?, decimalPlaces: Int?, timeFormat: String?)
  ) async {
    let startVal = layer.startValue
    let endVal = layer.endValue
    let delayMs = layer.delayMs ?? 0
    let durationMs = resolveCounterAnimationDurationMs(
      displayKind: layer.displayKind,
      durationMs: layer.durationMs,
      startValue: startVal,
      endValue: endVal
    )

    func format(_ value: Double) -> String {
      formatCounterLayerDisplay(
        value,
        displayKind: dispOpts.displayKind,
        decimalPlaces: dispOpts.decimalPlaces,
        timeFormat: dispOpts.timeFormat
      )
    }

    guard ctx.interactive else {
      displayText = format(startVal)
      return
    }

    let instant = durationMs <= 0 || startVal == endVal
    displayText = format(startVal)

    if instant {
      if delayMs > 0 {
        try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
        guard !Task.isCancelled else { return }
      }
      displayText = format(endVal)
      return
    }

    if delayMs > 0 {
      try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
      guard !Task.isCancelled else { return }
    }

    let durationSec = Double(durationMs) / 1_000
    let startTime = Date()
    while !Task.isCancelled {
      let t = min(1, Date().timeIntervalSince(startTime) / durationSec)
      displayText = format(startVal + (endVal - startVal) * t)
      if t >= 1 { break }
      try? await Task.sleep(nanoseconds: 16_000_000)
    }
    displayText = format(endVal)
  }
}
