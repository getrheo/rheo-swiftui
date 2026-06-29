import XCTest
@testable import RheoSwiftUI

final class ManifestResolveCacheTests: XCTestCase {
  private var defaults: UserDefaults!

  override func setUp() {
    super.setUp()
    let suite = "RheoSwiftUITests.ManifestResolveCache.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
  }

  private func sampleResponse() throws -> SdkResolveResponse {
    let json = """
    {
      "flowId": "00000000-0000-4000-8000-000000000001",
      "versionId": "00000000-0000-4000-8000-000000000002",
      "versionNumber": 1,
      "assignmentVersion": 2,
      "environment": "test",
      "channelId": "ch_test",
      "experimentId": null,
      "variantId": null,
      "manifest": {
        "flowId": "00000000-0000-4000-8000-000000000001",
        "version": 1,
        "defaultLocale": "en",
        "locales": ["en"],
        "screens": []
      },
      "mediaMap": {},
      "integrations": {}
    }
    """.data(using: .utf8)!
    return try JSONDecoder.rheo.decode(SdkResolveResponse.self, from: json)
  }

  func testCacheKeyNormalizesTrailingSlash() {
    let cache = ManifestResolveCache(userDefaults: defaults)
    let a = cache.cacheKey(
      apiBaseURL: URL(string: "https://api.test/")!,
      publishableKey: "ob_pk",
      channelId: "ch_1"
    )
    let b = cache.cacheKey(
      apiBaseURL: URL(string: "https://api.test")!,
      publishableKey: "ob_pk",
      channelId: "ch_1"
    )
    XCTAssertEqual(a, b)
  }

  func testShouldSendConditionalRequiresEtag() throws {
    let body = try sampleResponse()
    XCTAssertFalse(ManifestResolveCache.shouldSendConditional(nil))
    XCTAssertFalse(
      ManifestResolveCache.shouldSendConditional(
        ManifestResolveCacheEntry(etag: "  ", body: body, cachedAt: 0)
      )
    )
    XCTAssertTrue(
      ManifestResolveCache.shouldSendConditional(
        ManifestResolveCacheEntry(etag: "\"2-uuid\"", body: body, cachedAt: 0)
      )
    )
  }

  func testSaveAndLoadRoundTrip() throws {
    let cache = ManifestResolveCache(userDefaults: defaults)
    let key = cache.cacheKey(
      apiBaseURL: URL(string: "https://api.test")!,
      publishableKey: "ob_pk",
      channelId: "ch_rt"
    )
    let entry = ManifestResolveCacheEntry(
      etag: "\"1-uuid\"",
      body: try sampleResponse(),
      cachedAt: 1
    )
    cache.save(key: key, entry: entry)
    let loaded = cache.load(key: key)
    XCTAssertEqual(loaded?.etag, "\"1-uuid\"")
    XCTAssertEqual(loaded?.body.flowId, entry.body.flowId)
  }
}
