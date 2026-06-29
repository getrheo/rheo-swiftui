import XCTest
@testable import RheoSwiftUI

final class SmokeTests: XCTestCase {
  func testEntrypointMetadata() {
    XCTAssertEqual(Rheo.sdkName, "rheo-swiftui")
    XCTAssertFalse(Rheo.sdkVersion.isEmpty)
  }
}
