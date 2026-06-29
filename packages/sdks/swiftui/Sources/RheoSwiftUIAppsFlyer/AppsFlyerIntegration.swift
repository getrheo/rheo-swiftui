import Foundation
import RheoSwiftUI

/// Host-installed AppsFlyer bridge. Prefer `AppsFlyerAttributionProvider.automatic` or `FlowView(appsFlyerAttribution: .automatic)`.
public struct AppsFlyerAttributionProvider: AttributionProvider, @unchecked Sendable {
  private enum Mode: Sendable {
    case manual(
      observe: @Sendable (
        @escaping @Sendable (NormalizedAttributionSnapshot?) -> Void
      ) -> @Sendable () -> Void
    )
    case automatic
  }

  private let mode: Mode

  /// `true` for the built-in AppsFlyerLib listener provider (used to dedupe FlowView wiring).
  internal var usesBuiltInAutomaticListeners: Bool {
    if case .automatic = mode { return true }
    return false
  }

  /// Advanced: host subscribes to AppsFlyer callbacks and forwards normalized snapshots.
  public init(
    observe: @escaping @Sendable (
      @escaping @Sendable (NormalizedAttributionSnapshot?) -> Void
    ) -> @Sendable () -> Void
  ) {
    mode = .manual(observe: observe)
  }

  private init(mode: Mode) {
    self.mode = mode
  }

  /// Registers conversion + UDL listeners when `AppsFlyerLib` is linked in the host target; otherwise no-op.
  public static var automatic: AppsFlyerAttributionProvider {
    AppsFlyerAttributionProvider(mode: .automatic)
  }

  public func start(
    _ listener: @escaping @Sendable (NormalizedAttributionSnapshot?) -> Void
  ) -> @Sendable () -> Void {
    switch mode {
    case .manual(let observe):
      return observe(listener)
    case .automatic:
      return AppsFlyerLibAutomaticBridge.start(listener)
    }
  }
}

public enum RheoAppsFlyerIntegration {
  /// Flattens facet buckets into reserved `acquisition.*`, `link.*`, and `attribution.*` keys.
  public static func normalizedSnapshot(
    providerId: String = "appsflyer",
    acquisition: [String: JSONValue] = [:],
    link: [String: JSONValue] = [:],
    attribution: [String: JSONValue] = [:]
  ) -> NormalizedAttributionSnapshot {
    var facets = AppsFlyerAttributionFacets()
    facets.isOrganic = attributionBool(attribution["isOrganic"])
    facets.matchType = attributionString(attribution["matchType"])
    facets.source = acquisitionString(acquisition["source"])
    facets.campaign = acquisitionString(acquisition["campaign"])
    facets.campaignId = acquisitionString(acquisition["campaignId"])
    facets.adset = acquisitionString(acquisition["adset"])
    facets.adsetId = acquisitionString(acquisition["adsetId"])
    facets.creative = acquisitionString(acquisition["creative"])
    facets.creativeId = acquisitionString(acquisition["creativeId"])
    facets.channel = acquisitionString(acquisition["channel"])
    facets.linkEntry = linkString(link["entry"])
    facets.linkParams = linkExtParams(from: link)
    return AppsFlyerPayloadNormalizer.flatten(facets, providerId: providerId)
  }

  /// Maps a raw install / conversion dictionary (`onConversionDataSuccess`).
  public static func normalizedConversionSnapshot(
    _ root: [String: Any],
    capturedAtMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
  ) -> NormalizedAttributionSnapshot {
    let facets = AppsFlyerPayloadNormalizer.normalizeConversionPayload(root: root)
    return AppsFlyerPayloadNormalizer.flatten(facets, capturedAtMs: capturedAtMs)
  }

  /// Maps a raw deep-link / UDL dictionary (`didResolveDeepLink`).
  public static func normalizedDeepLinkSnapshot(
    _ root: [String: Any],
    capturedAtMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
  ) -> NormalizedAttributionSnapshot {
    let facets = AppsFlyerPayloadNormalizer.normalizeDeepLinkPayload(root: root)
    return AppsFlyerPayloadNormalizer.flatten(facets, capturedAtMs: capturedAtMs)
  }

  private static func attributionBool(_ value: JSONValue?) -> Bool? {
    guard let value else { return nil }
    if case .bool(let b) = value { return b }
    return nil
  }

  private static func attributionString(_ value: JSONValue?) -> String? {
    guard let value else { return nil }
    if case .string(let s) = value, !s.isEmpty { return s }
    return nil
  }

  private static func acquisitionString(_ value: JSONValue?) -> String? {
    attributionString(value)
  }

  private static func linkString(_ value: JSONValue?) -> String? {
    attributionString(value)
  }

  private static func linkExtParams(from link: [String: JSONValue]) -> [String: String] {
    var params: [String: String] = [:]
    for (key, value) in link where key != "entry" {
      if case .string(let s) = value, !s.isEmpty {
        let stripped = key.hasPrefix("ext.") ? String(key.dropFirst(4)) : key
        params[stripped] = s
      }
    }
    return params
  }
}
