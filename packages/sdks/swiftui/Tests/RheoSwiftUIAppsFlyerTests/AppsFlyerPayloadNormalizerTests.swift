import RheoSwiftUI
@testable import RheoSwiftUIAppsFlyer
import XCTest

final class AppsFlyerPayloadNormalizerTests: XCTestCase {
  func testNormalizeConversionPayload_mapsWrappedPayload() {
    let root: [String: Any] = [
      "data": [
        "af_status": "Non-organic",
        "media_source": "facebook",
        "campaign": "c1",
        "af_sub1": "alice",
        "deep_link_value": "promo_x",
      ] as [String: Any],
    ]

    let facets = AppsFlyerPayloadNormalizer.normalizeConversionPayload(root: root)

    XCTAssertEqual(facets.isOrganic, false)
    XCTAssertEqual(facets.source, "facebook")
    XCTAssertEqual(facets.campaign, "c1")
    XCTAssertEqual(facets.linkEntry, "promo_x")
    XCTAssertEqual(facets.linkParams["sub_1"], "alice")

    let snap = AppsFlyerPayloadNormalizer.flatten(facets, capturedAtMs: 1)
    XCTAssertEqual(snap.providerId, "appsflyer")
    XCTAssertEqual(snap.sdkAttributes["attribution.isOrganic"], .bool(false))
    XCTAssertEqual(snap.sdkAttributes["acquisition.source"], .string("facebook"))
    XCTAssertEqual(snap.sdkAttributes["acquisition.campaign"], .string("c1"))
    XCTAssertEqual(snap.sdkAttributes["link.entry"], .string("promo_x"))
    XCTAssertEqual(snap.sdkAttributes["link.ext.sub_1"], .string("alice"))
    XCTAssertTrue(AppsFlyerPayloadNormalizer.snapshotHasSignal(snap))
  }

  func testMergeFacets_overlayWinsScalars() {
    let base = AppsFlyerAttributionFacets(
      isOrganic: true,
      matchType: nil,
      source: "organic_placeholder",
      campaign: "old",
      campaignId: nil,
      adset: nil,
      adsetId: nil,
      creative: nil,
      creativeId: nil,
      channel: nil,
      linkEntry: "old_entry",
      linkParams: ["sub_1": "a"]
    )
    let overlay = AppsFlyerAttributionFacets(
      isOrganic: false,
      matchType: nil,
      source: nil,
      campaign: "new",
      campaignId: nil,
      adset: nil,
      adsetId: nil,
      creative: nil,
      creativeId: nil,
      channel: nil,
      linkEntry: nil,
      linkParams: ["sub_2": "b"]
    )
    let merged = AppsFlyerPayloadNormalizer.mergeFacets(base: base, overlay: overlay)
    XCTAssertEqual(merged.isOrganic, false)
    XCTAssertEqual(merged.source, "organic_placeholder")
    XCTAssertEqual(merged.campaign, "new")
    XCTAssertEqual(merged.linkEntry, "old_entry")
    XCTAssertEqual(merged.linkParams["sub_1"], "a")
    XCTAssertEqual(merged.linkParams["sub_2"], "b")
  }
}
