import XCTest
@testable import RheoSwiftUI

private final class ResolveStubURLProtocol: URLProtocol {
  nonisolated(unsafe) static var onRequest: ((URLRequest) throws -> (HTTPURLResponse, Data))?

  override class func canInit(with request: URLRequest) -> Bool {
    request.url?.path.hasSuffix("/v1/sdk/resolve") == true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

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

final class RheoAPIClientResolveTests: XCTestCase {
  private var defaults: UserDefaults!

  override func setUp() {
    super.setUp()
    let suite = "RheoSwiftUITests.RheoAPIClientResolve.\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    ResolveStubURLProtocol.onRequest = nil
  }

  private func makeClient() -> RheoAPIClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [ResolveStubURLProtocol.self]
    let session = URLSession(configuration: config)
    let rheoConfig = RheoConfig(
      publishableKey: "ob_pk_test",
      apiBaseURL: URL(string: "https://api.test")!,
      userId: "user-1",
      urlSession: session
    )
    return RheoAPIClient(config: rheoConfig, manifestCache: ManifestResolveCache(userDefaults: defaults))
  }

  private func resolveJSON() -> Data {
    """
    {
      "flowId": "00000000-0000-4000-8000-000000000001",
      "versionId": "00000000-0000-4000-8000-000000000002",
      "versionNumber": 1,
      "assignmentVersion": 1,
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
  }

  func testResolveStoresEtagOn200() async throws {
    ResolveStubURLProtocol.onRequest = { request in
      XCTAssertNil(request.value(forHTTPHeaderField: "If-None-Match"))
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["ETag": "\"1-uuid\""]
      )!
      return (response, self.resolveJSON())
    }
    let client = makeClient()
    _ = try await client.resolve(channelId: "ch_store")
    let cache = ManifestResolveCache(userDefaults: defaults)
    let key = cache.cacheKey(
      apiBaseURL: URL(string: "https://api.test")!,
      publishableKey: "ob_pk_test",
      channelId: "ch_store",
      locale: Locale.current.identifier
    )
    XCTAssertEqual(cache.load(key: key)?.etag, "\"1-uuid\"")
  }

  func testResolveUsesCacheOn304() async throws {
    let cache = ManifestResolveCache(userDefaults: defaults)
    let key = cache.cacheKey(
      apiBaseURL: URL(string: "https://api.test")!,
      publishableKey: "ob_pk_test",
      channelId: "ch_304",
      locale: Locale.current.identifier
    )
    let body = try JSONDecoder.rheo.decode(SdkResolveResponse.self, from: resolveJSON())
    cache.save(
      key: key,
      entry: ManifestResolveCacheEntry(etag: "\"1-uuid\"", body: body, cachedAt: 0)
    )

    ResolveStubURLProtocol.onRequest = { request in
      XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "\"1-uuid\"")
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 304,
        httpVersion: nil,
        headerFields: nil
      )!
      return (response, Data())
    }
    let client = makeClient()
    let resolved = try await client.resolve(channelId: "ch_304")
    XCTAssertEqual(resolved.flowId, body.flowId)
  }

  func testResolveDecodesMediaMapUrls() async throws {
    let assetId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    let mediaUrl = "https://cdn.test/hero.png"
    var json = String(data: resolveJSON(), encoding: .utf8)!
    json = json.replacingOccurrences(
      of: "\"mediaMap\": {}",
      with: "\"mediaMap\": { \"\(assetId)\": \"\(mediaUrl)\" }"
    )

    ResolveStubURLProtocol.onRequest = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      return (response, json.data(using: .utf8)!)
    }

    let resolved = try await makeClient().resolve(channelId: "ch_media")
    XCTAssertEqual(resolved.mediaMap[assetId], URL(string: mediaUrl))
  }
}
