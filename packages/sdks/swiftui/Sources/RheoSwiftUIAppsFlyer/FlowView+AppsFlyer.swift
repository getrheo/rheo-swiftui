import RheoSwiftUI
import SwiftUI

extension FlowView {
  public init(
    channelId: String,
    theme: ThemeMode? = nil,
    includeManifestInTerminalPayload: Bool = false,
    includePathInTerminalPayload: Bool = false,
    includeAnswerDetailInTerminalPayload: Bool = false,
    externalSurfacePresenter: @escaping ExternalSurfacePresenter = defaultExternalSurfacePresenter,
    appsFlyerAttribution: AppsFlyerAttributionMode = .off,
    attributionProviders: [AttributionProvider] = [],
    onFlowCompleted: (@Sendable (FlowTerminalSnapshot) -> Void)? = nil,
    onFlowAbandoned: (@Sendable (FlowTerminalSnapshot) -> Void)? = nil,
    onOAuthLogin: OAuthLoginHandler? = nil,
    onEmailPasswordAuth: EmailPasswordAuthHandler? = nil
  ) {
    self.init(
      channelId: channelId,
      theme: theme,
      includeManifestInTerminalPayload: includeManifestInTerminalPayload,
      includePathInTerminalPayload: includePathInTerminalPayload,
      includeAnswerDetailInTerminalPayload: includeAnswerDetailInTerminalPayload,
      externalSurfacePresenter: externalSurfacePresenter,
      attributionProviders: appsFlyerAttribution.resolvedAttributionProviders(appending: attributionProviders),
      onFlowCompleted: onFlowCompleted,
      onFlowAbandoned: onFlowAbandoned,
      onOAuthLogin: onOAuthLogin,
      onEmailPasswordAuth: onEmailPasswordAuth
    )
  }

  public init<F: View>(
    channelId: String,
    theme: ThemeMode? = nil,
    includeManifestInTerminalPayload: Bool = false,
    includePathInTerminalPayload: Bool = false,
    includeAnswerDetailInTerminalPayload: Bool = false,
    externalSurfacePresenter: @escaping ExternalSurfacePresenter = defaultExternalSurfacePresenter,
    appsFlyerAttribution: AppsFlyerAttributionMode = .off,
    attributionProviders: [AttributionProvider] = [],
    @ViewBuilder fallback: () -> F,
    onFlowCompleted: (@Sendable (FlowTerminalSnapshot) -> Void)? = nil,
    onFlowAbandoned: (@Sendable (FlowTerminalSnapshot) -> Void)? = nil,
    onOAuthLogin: OAuthLoginHandler? = nil,
    onEmailPasswordAuth: EmailPasswordAuthHandler? = nil
  ) {
    self.init(
      channelId: channelId,
      theme: theme,
      includeManifestInTerminalPayload: includeManifestInTerminalPayload,
      includePathInTerminalPayload: includePathInTerminalPayload,
      includeAnswerDetailInTerminalPayload: includeAnswerDetailInTerminalPayload,
      externalSurfacePresenter: externalSurfacePresenter,
      attributionProviders: appsFlyerAttribution.resolvedAttributionProviders(appending: attributionProviders),
      fallback: fallback,
      onFlowCompleted: onFlowCompleted,
      onFlowAbandoned: onFlowAbandoned,
      onOAuthLogin: onOAuthLogin,
      onEmailPasswordAuth: onEmailPasswordAuth
    )
  }
}
