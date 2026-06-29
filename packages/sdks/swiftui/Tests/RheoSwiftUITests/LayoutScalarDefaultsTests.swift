import XCTest
@testable import RheoSwiftUI

/// Guards parity with `packages/flow-runtime/src/layout/scalarLayoutDefaults.ts`.
final class LayoutScalarDefaultsTests: XCTestCase {
  func testGapDefaults() {
    XCTAssertEqual(LayoutScalarDefaults.stackGap, 12)
    XCTAssertEqual(LayoutScalarDefaults.choiceGap, 8)
    XCTAssertEqual(LayoutScalarDefaults.buttonGap, 8)
    XCTAssertEqual(LayoutScalarDefaults.authGap, 8)
    XCTAssertEqual(LayoutScalarDefaults.oauthProviderGap, 8)
    XCTAssertEqual(LayoutScalarDefaults.hyperlinkGap, 0)
  }

  func testFeedbackDimensionDefaults() {
    XCTAssertEqual(LayoutScalarDefaults.progressLinearHeight, 6)
    XCTAssertEqual(LayoutScalarDefaults.loaderLinearHeight, 6)
    XCTAssertEqual(LayoutScalarDefaults.loaderCircularSize, 48)
    XCTAssertEqual(LayoutScalarDefaults.loaderStrokeWidth, 4)
  }
}
