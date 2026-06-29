import XCTest
@testable import RheoSwiftUI

final class ManifestDecodingTests: XCTestCase {
  func testMinimalManifestDecodes() throws {
    let manifest = try decodeFixture("minimal-flow", as: FlowManifest.self)
    XCTAssertEqual(manifest.entryScreenId, "scr_start")
    XCTAssertEqual(manifest.screens.count, 2)
    XCTAssertEqual(manifest.decisionNodes.count, 0)
  }

  func testAuthLayersDecode() throws {
    let manifest = try decodeFixture("auth-flow", as: FlowManifest.self)
    let body = manifest.screens[0].regions.body
    XCTAssertEqual(body.children.count, 2)
    guard case .oauthLogin(let oauth) = body.children[0] else {
      return XCTFail("expected oauth layer")
    }
    XCTAssertEqual(oauth.children.first?.provider, "google")
    guard case .emailPasswordAuth(let email) = body.children[1] else {
      return XCTFail("expected email/password layer")
    }
    XCTAssertEqual(email.mode, .signIn)
  }
}

func decodeFixture<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
  let url = Bundle.module.url(forResource: name, withExtension: "json")!
  let data = try Data(contentsOf: url)
  return try JSONDecoder.rheo.decode(T.self, from: data)
}
