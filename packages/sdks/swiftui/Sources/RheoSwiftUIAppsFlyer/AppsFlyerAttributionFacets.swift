import Foundation

/// Provider-agnostic facet buckets before flattening to `sdkAttributes` (parity with `@getrheo/attribution`).
struct AppsFlyerAttributionFacets: Equatable, Sendable {
  var isOrganic: Bool?
  var matchType: String?
  var source: String?
  var campaign: String?
  var campaignId: String?
  var adset: String?
  var adsetId: String?
  var creative: String?
  var creativeId: String?
  var channel: String?
  var linkEntry: String?
  var linkParams: [String: String] = [:]
}
