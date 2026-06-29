import Foundation
import RheoSwiftUI

enum AppsFlyerPayloadNormalizer {
  static let providerId = "appsflyer"

  static func extractAppsFlyerPayload(root: [String: Any]) -> [String: Any] {
    if let data = root["data"] as? [String: Any] {
      return data
    }
    return root
  }

  private static func str(_ row: [String: Any], keys: [String]) -> String? {
    for key in keys {
      guard let raw = row[key] else { continue }
      if let s = raw as? String, !s.isEmpty { return s }
      if let n = raw as? NSNumber { return n.stringValue }
      if let i = raw as? Int { return String(i) }
      if let d = raw as? Double, d.isFinite { return String(d) }
    }
    return nil
  }

  /// Maps install / conversion payloads (`onInstallConversionData` / `onConversionDataSuccess`).
  static func normalizeConversionPayload(root: [String: Any]) -> AppsFlyerAttributionFacets {
    let row = extractAppsFlyerPayload(root: root)
    let afStatus = str(row, keys: ["af_status"]) ?? ""
    let isOrganic = afStatus.lowercased() == "organic"

    var linkParams: [String: String] = [:]
    for i in 1 ... 10 {
      if let v = str(row, keys: ["af_sub\(i)"]) {
        linkParams["sub_\(i)"] = v
      }
    }

    return AppsFlyerAttributionFacets(
      isOrganic: isOrganic,
      matchType: str(row, keys: ["match_type", "af_match_type"]),
      source: str(row, keys: ["media_source", "pid"]),
      campaign: str(row, keys: ["campaign", "af_campaign"]),
      campaignId: str(row, keys: ["campaign_id", "af_campaign_id"]),
      adset: str(row, keys: ["adset", "af_adset"]),
      adsetId: str(row, keys: ["adset_id", "af_adset_id"]),
      creative: str(row, keys: ["ad", "af_ad"]),
      creativeId: str(row, keys: ["ad_id", "af_ad_id"]),
      channel: str(row, keys: ["channel"]),
      linkEntry: str(row, keys: ["deep_link_value", "af_dp"]),
      linkParams: linkParams
    )
  }

  private static func mergeParams(into params: inout [String: String], from src: [String: Any]) {
    for (key, value) in src {
      let safeKey = key.replacingOccurrences(of: ".", with: "_")
      if let s = value as? String, !s.isEmpty {
        params[safeKey] = s
      } else if let n = value as? NSNumber {
        params[safeKey] = n.stringValue
      } else if let i = value as? Int {
        params[safeKey] = String(i)
      } else if let d = value as? Double, d.isFinite {
        params[safeKey] = String(d)
      }
    }
  }

  /// Maps deep-link / OneLink callbacks (`onDeepLink` / `didResolveDeepLink`).
  static func normalizeDeepLinkPayload(root: [String: Any]) -> AppsFlyerAttributionFacets {
    let row = root
    let deepCandidate =
      row["deepLink"] as? [String: Any]
      ?? row["deep_link"] as? [String: Any]
      ?? row["data"] as? [String: Any]
      ?? row
    let payload = extractAppsFlyerPayload(root: deepCandidate)

    var linkParams: [String: String] = [:]
    if let clickEvent = payload["click_event"] as? [String: Any] {
      mergeParams(into: &linkParams, from: clickEvent)
    }
    mergeParams(into: &linkParams, from: payload)

    let afStatus = str(payload, keys: ["af_status"])
    let isOrganic: Bool? = afStatus.map { $0.lowercased() == "organic" }

    return AppsFlyerAttributionFacets(
      isOrganic: isOrganic,
      matchType: str(payload, keys: ["match_type", "af_match_type"]),
      source: str(payload, keys: ["media_source", "pid"]),
      campaign: str(payload, keys: ["campaign", "af_campaign"]),
      campaignId: str(payload, keys: ["campaign_id", "af_campaign_id"]),
      adset: str(payload, keys: ["adset", "af_adset"]),
      adsetId: str(payload, keys: ["adset_id", "af_adset_id"]),
      creative: str(payload, keys: ["ad", "af_ad"]),
      creativeId: str(payload, keys: ["ad_id", "af_ad_id"]),
      channel: str(payload, keys: ["channel"]),
      linkEntry: str(payload, keys: ["deep_link_value"])
        ?? str(deepCandidate, keys: ["deep_link_value"])
        ?? str(row, keys: ["deep_link_value"]),
      linkParams: linkParams
    )
  }

  /// Merges install + deep-link facets for the same provider session (parity with `mergeAttributionSnapshots`).
  static func mergeFacets(base: AppsFlyerAttributionFacets?, overlay: AppsFlyerAttributionFacets) -> AppsFlyerAttributionFacets {
    guard let base else { return overlay }
    var linkParams = base.linkParams
    for (k, v) in overlay.linkParams {
      linkParams[k] = v
    }
    return AppsFlyerAttributionFacets(
      isOrganic: overlay.isOrganic ?? base.isOrganic,
      matchType: overlay.matchType ?? base.matchType,
      source: overlay.source ?? base.source,
      campaign: overlay.campaign ?? base.campaign,
      campaignId: overlay.campaignId ?? base.campaignId,
      adset: overlay.adset ?? base.adset,
      adsetId: overlay.adsetId ?? base.adsetId,
      creative: overlay.creative ?? base.creative,
      creativeId: overlay.creativeId ?? base.creativeId,
      channel: overlay.channel ?? base.channel,
      linkEntry: overlay.linkEntry ?? base.linkEntry,
      linkParams: linkParams
    )
  }

  private static func sanitizeExtKey(_ raw: String) -> String {
    let filtered = raw.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || $0 == "_" }
    return String(String.UnicodeScalarView(filtered).prefix(64))
  }

  static func flatten(
    _ facets: AppsFlyerAttributionFacets,
    providerId: String = AppsFlyerPayloadNormalizer.providerId,
    capturedAtMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
  ) -> NormalizedAttributionSnapshot {
    var attrs: [String: JSONValue] = [:]
    attrs["attribution.provider"] = .string(providerId)

    if let isOrganic = facets.isOrganic {
      attrs["attribution.isOrganic"] = .bool(isOrganic)
    }
    if let matchType = facets.matchType, !matchType.isEmpty {
      attrs["attribution.matchType"] = .string(matchType)
    }

    let setStr = { (key: String, value: String?) in
      guard let value, !value.isEmpty else { return }
      attrs[key] = .string(value)
    }

    setStr("acquisition.source", facets.source)
    setStr("acquisition.campaign", facets.campaign)
    setStr("acquisition.campaignId", facets.campaignId)
    setStr("acquisition.adset", facets.adset)
    setStr("acquisition.adsetId", facets.adsetId)
    setStr("acquisition.creative", facets.creative)
    setStr("acquisition.creativeId", facets.creativeId)
    setStr("acquisition.channel", facets.channel)
    setStr("link.entry", facets.linkEntry)

    for (rawKey, rawVal) in facets.linkParams where !rawVal.isEmpty {
      let sk = sanitizeExtKey(rawKey)
      guard !sk.isEmpty else { continue }
      attrs["link.ext.\(sk)"] = .string(rawVal)
    }

    return NormalizedAttributionSnapshot(
      providerId: providerId,
      capturedAtMs: capturedAtMs,
      sdkAttributes: attrs
    )
  }

  static func snapshotHasSignal(_ snapshot: NormalizedAttributionSnapshot) -> Bool {
    snapshot.sdkAttributes.keys.contains { $0 != "attribution.provider" }
  }
}
