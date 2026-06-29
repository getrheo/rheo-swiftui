import XCTest
@testable import RheoSwiftUI

private final class ResolveAllStubURLProtocol: URLProtocol {
  nonisolated(unsafe) static var onRequest: ((URLRequest) throws -> (HTTPURLResponse, Data))?

  override class func canInit(with request: URLRequest) -> Bool {
    request.url?.path.hasSuffix("/v1/sdk/resolve-all") == true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    guard let handler = Self.onRequest else {
      client?.urlProtocol(self, didFailWithError: URLError(.badURL))
      return
    }
    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

final class RheoAPIClientResolveAllTests: XCTestCase {
  private var defaults: UserDefaults!

  override func setUp() {
    super.setUp()
    let suite = "RheoSwiftUITests.RheoAPIClientResolveAll.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    ResolveAllStubURLProtocol.onRequest = nil
  }

  private func makeClient(cache: ManifestResolveCache) -> RheoAPIClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [ResolveAllStubURLProtocol.self]
    let session = URLSession(configuration: config)
    let rheoConfig = RheoConfig(
      publishableKey: "ob_pk_test",
      apiBaseURL: URL(string: "https://api.test")!,
      userId: "user-1",
      locale: "en",
      urlSession: session
    )
    return RheoAPIClient(config: rheoConfig, manifestCache: cache)
  }

  private func channelsJSON() -> Data {
    """
    { "channels": [
      {
        "flowId": "00000000-0000-4000-8000-000000000001",
        "versionId": "ver-a",
        "versionNumber": 1,
        "assignmentVersion": 3,
        "environment": "test",
        "channelId": "ch_a",
        "experimentId": null,
        "variantId": null,
        "manifest": { "flowId": "00000000-0000-4000-8000-000000000001", "version": 1, "defaultLocale": "en", "locales": ["en"], "screens": [] },
        "mediaMap": {},
        "integrations": {}
      },
      {
        "flowId": "00000000-0000-4000-8000-000000000001",
        "versionId": "ver-b",
        "versionNumber": 1,
        "assignmentVersion": 7,
        "environment": "test",
        "channelId": "ch_b",
        "experimentId": null,
        "variantId": null,
        "manifest": { "flowId": "00000000-0000-4000-8000-000000000001", "version": 1, "defaultLocale": "en", "locales": ["en"], "screens": [] },
        "mediaMap": {},
        "integrations": {}
      }
    ] }
    """.data(using: .utf8)!
  }

  func testResolveAllWritesEachChannelToCache() async throws {
    ResolveAllStubURLProtocol.onRequest = { request in
      XCTAssertNil(request.value(forHTTPHeaderField: "X-Rheo-Channel"))
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (response, self.channelsJSON())
    }
    let cache = ManifestResolveCache(userDefaults: defaults)
    let client = makeClient(cache: cache)
    let channels = try await client.resolveAll()
    XCTAssertEqual(channels.count, 2)

    let keyA = cache.cacheKey(
      apiBaseURL: URL(string: "https://api.test")!,
      publishableKey: "ob_pk_test",
      channelId: "ch_a",
      locale: "en"
    )
    XCTAssertEqual(cache.load(key: keyA)?.etag, "\"3-ver-a\"")

    let keyB = cache.cacheKey(
      apiBaseURL: URL(string: "https://api.test")!,
      publishableKey: "ob_pk_test",
      channelId: "ch_b",
      locale: "en"
    )
    XCTAssertEqual(cache.load(key: keyB)?.etag, "\"7-ver-b\"")
  }
}
