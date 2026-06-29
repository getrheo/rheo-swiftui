import SwiftUI

public struct SwiftUILayerRenderer: View {
  public var manifest: FlowManifest
  public var screen: Screen
  public var locale: String
  public var interactive: Bool
  public var mediaMap: [String: URL]
  public var theme: ThemeMode
  public var interpolationContext: InterpolationContext?
  public var branding: Branding?
  public var onRespond: (StepResponse) -> Void
  public var onAction: (ButtonAction, String, AppReviewButtonCommit?) -> Void
  public var onHyperlinkOpened: (String, String) -> Void
  public var oauthLoginHandler: OAuthLoginHandler?
  public var emailPasswordAuthHandler: EmailPasswordAuthHandler?
  @StateObject private var draftStore: ScreenInputDraftStore
  @StateObject private var checkboxStore: CheckboxAckStore
  @StateObject private var mediaPlayback: MediaPlaybackCoordinator

  public init(
    manifest: FlowManifest,
    screen: Screen,
    locale: String = "en",
    interactive: Bool = true,
    mediaMap: [String: URL] = [:],
    theme: ThemeMode = .dark,
    interpolationContext: InterpolationContext? = nil,
    branding: Branding? = nil,
    onRespond: @escaping (StepResponse) -> Void = { _ in },
    onAction: @escaping (ButtonAction, String, AppReviewButtonCommit?) -> Void = { _, _, _ in },
    onHyperlinkOpened: @escaping (String, String) -> Void = { _, _ in },
    oauthLoginHandler: OAuthLoginHandler? = nil,
    emailPasswordAuthHandler: EmailPasswordAuthHandler? = nil
  ) {
    self.manifest = manifest
    self.screen = screen
    self.locale = locale
    self.interactive = interactive
    self.mediaMap = mediaMap
    self.theme = theme
    self.interpolationContext = interpolationContext
    self.branding = branding
    self.onRespond = onRespond
    self.onAction = onAction
    self.onHyperlinkOpened = onHyperlinkOpened
    self.oauthLoginHandler = oauthLoginHandler
    self.emailPasswordAuthHandler = emailPasswordAuthHandler
    _draftStore = StateObject(wrappedValue: ScreenInputDraftStore(screen: screen))
    _checkboxStore = StateObject(wrappedValue: CheckboxAckStore(screen: screen))
    _mediaPlayback = StateObject(wrappedValue: MediaPlaybackCoordinator())
  }

  public var body: some View {
    GeometryReader { geo in
      let width = max(Double(geo.size.width), defaultPreviewViewportWidthPx)
      let resolvedShell = resolveScreenContainerStyleAtWidth(
        screen.containerStyle,
        screen.containerStyleBreakpoints,
        width: width
      )
      let shellMargin = resolvedShell?.margin
      let deviceSafeArea = Padding(
        t: Double(geo.safeAreaInsets.top),
        r: 0,
        b: Double(geo.safeAreaInsets.bottom),
        l: 0
      )
      let shellForStyle: CommonStyle? = {
        guard resolvedShell != nil else { return nil }
        var common = resolvedShell!.asCommonStyle
        common.padding = resolveEffectiveScreenShellPadding(
          manual: resolvedShell?.padding,
          insetSafeArea: resolvedShell?.insetSafeArea,
          safeAreaInsets: deviceSafeArea
        )
        common.margin = nil
        return common
      }()
      let bgFill = resolveScreenBackgroundFillAtWidth(screen, width: width)
      let ctx = LayerRendererContext(
        manifest: manifest,
        screen: screen,
        locale: locale,
        interactive: interactive,
        mediaMap: mediaMap,
        theme: theme,
        isRegionRoot: false,
        regionKind: nil,
        regionHeight: geo.size.height,
        interpolationContext: interpolationContext,
        branding: branding,
        previewWidthPx: width,
        onRespond: onRespond,
        onAction: onAction,
        onHyperlinkOpened: onHyperlinkOpened,
        oauthLoginHandler: oauthLoginHandler,
        emailPasswordAuthHandler: emailPasswordAuthHandler
      )
      ZStack {
        screenContainerFallbackColor(for: theme)
        if let bgFill {
          ScreenShellBackgroundStack(
            fill: bgFill,
            theme: manifest.theme,
            branding: branding,
            mode: theme,
            mediaMap: mediaMap,
            screenId: screen.id,
            interactive: interactive,
            onRespond: onRespond
          )
          .environmentObject(mediaPlayback)
          .allowsHitTesting(false)
        }
        VStack(spacing: 0) {
          if let header = screen.regions.header {
            LayerView(layer: .stack(header), ctx: ctx.regionRoot(.header))
              .environmentObject(draftStore)
              .environmentObject(checkboxStore)
              .environmentObject(mediaPlayback)
              .fixedSize(horizontal: false, vertical: true)
          }
          ScrollView {
            LayerView(layer: .stack(screen.regions.body), ctx: ctx.regionRoot(.body))
              .environmentObject(draftStore)
              .environmentObject(checkboxStore)
              .environmentObject(mediaPlayback)
              .frame(maxWidth: .infinity, alignment: .topLeading)
          }
          .environment(\.rheoLayoutWidth, geo.size.width)
          .rheoScrollCanvas(mode: theme, mediaBackdrop: bgFill?.kind == .image || bgFill?.kind == .video)
          if let footer = screen.regions.footer {
            LayerView(layer: .stack(footer), ctx: ctx.regionRoot(.footer))
              .environmentObject(draftStore)
              .environmentObject(checkboxStore)
              .environmentObject(mediaPlayback)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      }
      .rheoCommonStyle(shellWithoutBackground(shellForStyle), theme: manifest.theme, mode: theme, containerWidth: geo.size.width, branding: branding)
      .padding(.top, CGFloat(shellMargin?.t ?? 0))
      .padding(.trailing, CGFloat(shellMargin?.r ?? 0))
      .padding(.bottom, CGFloat(shellMargin?.b ?? 0))
      .padding(.leading, CGFloat(shellMargin?.l ?? 0))
      .environment(\.colorScheme, theme == .dark ? .dark : .light)
      .environment(\.motionController, MotionController(screen: screen))
    }
  }
}

private struct LayerView: View {
  var layer: Layer
  var ctx: LayerRendererContext

  var body: some View {
    // Resolve the layer's common style at the current viewport so the
    // flex-shell modifier reads the same width/height as the inner
    // chrome, mirroring how `LayerRenderer.tsx` derives `resolved` once
    // per layer in the web sim.
    let resolved = resolvedCommonStyleForLayer(layer, previewWidthPx: ctx.previewWidthPx)
    LayerMotionShell(layer: layer) {
      renderLayer(layer, ctx: ctx)
    }
    .rheoFlowChildLayout(resolved)
  }

  @ViewBuilder private func renderLayer(_ layer: Layer, ctx: LayerRendererContext) -> some View {
    switch layer {
    case .stack(let layer):
      StackLayerView(layer: layer, ctx: ctx)
    case .text(let layer):
      TextLayerView(layer: layer, ctx: ctx)
    case .hyperlink(let layer):
      HyperlinkLayerView(layer: layer, ctx: ctx)
    case .image(let layer):
      ImageLayerView(layer: layer, ctx: ctx)
    case .lottie(let layer):
      LottieLayerView(layer: layer, ctx: ctx)
    case .video(let layer):
      VideoLayerView(layer: layer, ctx: ctx)
    case .icon(let layer):
      IconLayerView(layer: layer, ctx: ctx)
    case .button(let layer):
      ButtonLayerView(layer: layer, ctx: ctx)
    case .backButton(let layer):
      BackButtonLayerView(layer: layer, ctx: ctx)
    case .progress(let layer):
      ProgressLayerView(layer: layer, ctx: ctx)
    case .loader(let layer):
      LoaderLayerView(layer: layer, ctx: ctx)
    case .counter(let layer):
      CounterLayerView(layer: layer, ctx: ctx)
    case .checkbox(let layer):
      CheckboxLayerView(layer: layer, ctx: ctx)
    case .singleChoice(let layer):
      SingleChoiceLayerView(layer: layer, ctx: ctx)
    case .multipleChoice(let layer):
      MultipleChoiceLayerView(layer: layer, ctx: ctx)
    case .textInput(let layer):
      TextInputLayerView(layer: layer, ctx: ctx)
    case .scaleInput(let layer):
      ScaleInputLayerView(layer: layer, ctx: ctx)
    case .oauthLogin(let layer):
      OAuthLoginView(layer: layer, ctx: ctx)
    case .emailPasswordAuth(let layer):
      EmailPasswordAuthView(layer: layer, ctx: ctx)
    case .carousel(let layer):
      CarouselLayerView(layer: layer, ctx: ctx)
    case .oauthProvider, .emailPasswordField, .emailPasswordSubmit:
      EmptyView()
    }
  }
}

private func shellWithoutBackground(_ style: CommonStyle?) -> CommonStyle? {
  guard var style else { return nil }
  style.background = nil
  return style
}

extension LayerRendererContext {
  func regionRoot(_ kind: RegionKind) -> LayerRendererContext {
    var next = self
    next.isRegionRoot = true
    next.regionKind = kind
    return next
  }

  func child() -> LayerRendererContext {
    var next = self
    next.isRegionRoot = false
    next.regionKind = nil
    return next
  }
}

@ViewBuilder
func renderChild(_ child: Layer, ctx: LayerRendererContext) -> some View {
  LayerView(layer: child, ctx: ctx.child())
}
