import Foundation
import RheoSwiftUI

public enum AppsFlyerAttributionMode: Sendable {
  case off
  case automatic
  case custom(AppsFlyerAttributionProvider)
}

extension AppsFlyerAttributionMode {
  /// Merges automatic/custom AppsFlyer providers with explicit `attributionProviders`, deduping built-in automatic listeners.
  public func resolvedAttributionProviders(
    appending existing: [AttributionProvider] = []
  ) -> [AttributionProvider] {
    switch self {
    case .off:
      return existing
    case .automatic:
      let automatic = AppsFlyerAttributionProvider.automatic
      let filtered = existing.filter { provider in
        guard let af = provider as? AppsFlyerAttributionProvider else { return true }
        return !af.usesBuiltInAutomaticListeners
      }
      return [automatic] + filtered
    case .custom(let custom):
      return existing + [custom]
    }
  }
}
