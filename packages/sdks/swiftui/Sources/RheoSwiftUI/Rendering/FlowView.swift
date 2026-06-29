import SwiftUI

public struct FlowView: View {
  @Environment(\.rheoRuntime) private var runtime
  @Environment(\.colorScheme) private var colorScheme
  public var channelId: String
  /// When `nil`, follows the host `colorScheme` (simulator / app light or dark). Set to pin a palette.
  public var theme: ThemeMode?
  /// Host-owned escape hatch when manifest resolve fails (full-bleed; no Rheo telemetry).
  private let customResolveFallback: AnyView?
  public var includeManifestInTerminalPayload: Bool
  public var includePathInTerminalPayload: Bool
  public var includeAnswerDetailInTerminalPayload: Bool
  public var externalSurfacePresenter: ExternalSurfacePresenter
  public var attributionProviders: [AttributionProvider]
  public var onFlowCompleted: (@Sendable (FlowTerminalSnapshot) -> Void)?
  public var onFlowAbandoned: (@Sendable (FlowTerminalSnapshot) -> Void)?
  public var onOAuthLogin: OAuthLoginHandler?
  public var onEmailPasswordAuth: EmailPasswordAuthHandler?

  @StateObject private var box = ControllerBox()

  public init(
    channelId: String,
    theme: ThemeMode? = nil,
    includeManifestInTerminalPayload: Bool = false,
    includePathInTerminalPayload: Bool = false,
    includeAnswerDetailInTerminalPayload: Bool = false,
    externalSurfacePresenter: @escaping ExternalSurfacePresenter = defaultExternalSurfacePresenter,
    attributionProviders: [AttributionProvider] = [],
    onFlowCompleted: (@Sendable (FlowTerminalSnapshot) -> Void)? = nil,
    onFlowAbandoned: (@Sendable (FlowTerminalSnapshot) -> Void)? = nil,
    onOAuthLogin: OAuthLoginHandler? = nil,
    onEmailPasswordAuth: EmailPasswordAuthHandler? = nil
  ) {
    self.channelId = channelId
    self.theme = theme
    self.customResolveFallback = nil
    self.includeManifestInTerminalPayload = includeManifestInTerminalPayload
    self.includePathInTerminalPayload = includePathInTerminalPayload
    self.includeAnswerDetailInTerminalPayload = includeAnswerDetailInTerminalPayload
    self.externalSurfacePresenter = externalSurfacePresenter
    self.attributionProviders = attributionProviders
    self.onFlowCompleted = onFlowCompleted
    self.onFlowAbandoned = onFlowAbandoned
    self.onOAuthLogin = onOAuthLogin
    self.onEmailPasswordAuth = onEmailPasswordAuth
  }

  public init<F: View>(
    channelId: String,
    theme: ThemeMode? = nil,
    includeManifestInTerminalPayload: Bool = false,
    includePathInTerminalPayload: Bool = false,
    includeAnswerDetailInTerminalPayload: Bool = false,
    externalSurfacePresenter: @escaping ExternalSurfacePresenter = defaultExternalSurfacePresenter,
    attributionProviders: [AttributionProvider] = [],
    @ViewBuilder fallback: () -> F,
    onFlowCompleted: (@Sendable (FlowTerminalSnapshot) -> Void)? = nil,
    onFlowAbandoned: (@Sendable (FlowTerminalSnapshot) -> Void)? = nil,
    onOAuthLogin: OAuthLoginHandler? = nil,
    onEmailPasswordAuth: EmailPasswordAuthHandler? = nil
  ) {
    self.channelId = channelId
    self.theme = theme
    self.customResolveFallback = AnyView(fallback())
    self.includeManifestInTerminalPayload = includeManifestInTerminalPayload
    self.includePathInTerminalPayload = includePathInTerminalPayload
    self.includeAnswerDetailInTerminalPayload = includeAnswerDetailInTerminalPayload
    self.externalSurfacePresenter = externalSurfacePresenter
    self.attributionProviders = attributionProviders
    self.onFlowCompleted = onFlowCompleted
    self.onFlowAbandoned = onFlowAbandoned
    self.onOAuthLogin = onOAuthLogin
    self.onEmailPasswordAuth = onEmailPasswordAuth
  }

  private var effectiveTheme: ThemeMode {
    effectiveThemeMode(explicit: theme, colorScheme: colorScheme)
  }

  public var body: some View {
    content
      .preferredColorScheme(effectiveTheme == .dark ? .dark : .light)
      .task(id: runtime == nil ? "missing" : channelId) {
        guard let runtime else {
          box.error = RheoSDKError.missingRuntime
          return
        }
        let controller = FlowController(
          channelId: channelId,
          runtime: runtime,
          includeManifestInTerminalPayload: includeManifestInTerminalPayload,
          includePathInTerminalPayload: includePathInTerminalPayload,
          includeAnswerDetailInTerminalPayload: includeAnswerDetailInTerminalPayload,
          externalSurfacePresenter: externalSurfacePresenter,
          attributionProviders: attributionProviders,
          onFlowCompleted: onFlowCompleted,
          onFlowAbandoned: onFlowAbandoned
        )
        controller.seedFromCacheIfWarm()
        box.controller = controller
        await controller.resolve()
      }
  }

  @ViewBuilder private var content: some View {
    if let controller = box.controller {
      FlowControllerContent(
        controller: controller,
        theme: effectiveTheme,
        customResolveFallback: customResolveFallback,
        onOAuthLogin: onOAuthLogin,
        onEmailPasswordAuth: onEmailPasswordAuth
      )
    } else if let error = box.error {
      Text(error.localizedDescription)
        .foregroundStyle(effectiveTheme == .dark ? .white : .black)
        .multilineTextAlignment(.center)
        .padding(24)
    } else {
      ProgressView()
    }
  }
}

@MainActor
private final class ControllerBox: ObservableObject {
  @Published var controller: FlowController?
  @Published var error: Error?
}

private struct FlowControllerContent: View {
  @ObservedObject var controller: FlowController
  var theme: ThemeMode
  var customResolveFallback: AnyView?
  var onOAuthLogin: OAuthLoginHandler?
  var onEmailPasswordAuth: EmailPasswordAuthHandler?

  var body: some View {
    if controller.loading {
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if controller.resolveFailed {
      if let customResolveFallback {
        customResolveFallback
      } else {
        DefaultResolveErrorView(theme: theme) {
          Task { await controller.retry() }
        }
      }
    } else if let manifest = controller.manifest, let screen = controller.screen, controller.state?.status == .running {
      ScreenChrome(theme: theme) {
        GeometryReader { geo in
          SwiftUILayerRenderer(
            manifest: manifest,
            screen: screen,
            locale: controller.state?.session.locale ?? "en",
            interactive: true,
            mediaMap: controller.mediaMap,
            theme: theme,
            interpolationContext: controller.state.map {
              InterpolationContext(
                responses: $0.responses,
                customProperties: controller.customProperties,
                canGoBack: $0.history.count > 1
              )
            },
            branding: controller.branding,
            onRespond: controller.respond,
            onAction: { action, layerId, commit in
              controller.relayButtonAction(action, layerId: layerId, appReviewCommit: commit)
            },
            onHyperlinkOpened: controller.trackExternalLinkOpened,
            oauthLoginHandler: onOAuthLogin,
            emailPasswordAuthHandler: onEmailPasswordAuth
          )
          .frame(width: geo.size.width, height: geo.size.height)
          .id(screen.id)
        }
      }
    } else {
      EmptyView()
    }
  }
}
