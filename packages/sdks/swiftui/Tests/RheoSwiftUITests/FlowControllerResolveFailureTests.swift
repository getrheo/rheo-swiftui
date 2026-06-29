import XCTest
@testable import RheoSwiftUI

private final class ResolveFailureStubURLProtocol: URLProtocol {
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

@MainActor
final class FlowControllerResolveFailureTests: XCTestCase {
  func testResolveFailedWhenResolveThrows() async {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [ResolveFailureStubURLProtocol.self]
    ResolveFailureStubURLProtocol.onRequest = { _ in
      throw URLError(.notConnectedToInternet)
    }
    let runtime = RheoRuntime(
      config: RheoConfig(
        publishableKey: "ob_pk_test",
        apiBaseURL: URL(string: "https://api.test")!,
        userId: "user-1",
        urlSession: URLSession(configuration: config)
      )
    )
    let controller = FlowController(channelId: "ch_test", runtime: runtime)
    await controller.resolve()
    XCTAssertTrue(controller.resolveFailed)
    XCTAssertNotNil(controller.error)
    XCTAssertNil(controller.resolved)
  }

  func testRetryClearsResolveFailedOnSuccess() async {
    var callCount = 0
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [ResolveFailureStubURLProtocol.self]
    ResolveFailureStubURLProtocol.onRequest = { _ in
      callCount += 1
      if callCount == 1 {
        throw URLError(.notConnectedToInternet)
      }
      let body = """
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
          "schemaVersion": 7,
          "version": 1,
          "defaultLocale": "en",
          "locales": ["en"],
          "entryScreenId": "scr_a",
          "screens": [{
            "id": "scr_a",
            "name": "A",
            "regions": {
              "body": {
                "id": "lyr_stack",
                "kind": "stack",
                "direction": "vertical",
                "children": []
              }
            },
            "next": { "default": null }
          }],
          "decisionNodes": [],
          "externalSurfaceNodes": [],
          "sdkAttributeKeys": []
        },
        "mediaMap": {},
        "integrations": {}
      }
      """.data(using: .utf8)!
      let response = HTTPURLResponse(
        url: URL(string: "https://api.test/v1/sdk/resolve")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["ETag": "\"1-uuid\""]
      )!
      return (response, body)
    }
    let runtime = RheoRuntime(
      config: RheoConfig(
        publishableKey: "ob_pk_test",
        apiBaseURL: URL(string: "https://api.test")!,
        userId: "user-1",
        urlSession: URLSession(configuration: config)
      )
    )
    let controller = FlowController(channelId: "ch_test", runtime: runtime)
    await controller.resolve()
    XCTAssertTrue(controller.resolveFailed)
    await controller.retry()
    XCTAssertFalse(controller.resolveFailed)
    XCTAssertNotNil(controller.resolved)
    XCTAssertEqual(callCount, 2)
  }
}
