import XCTest
@testable import RheoSwiftUI

final class IconRendererTests: XCTestCase {
  func testIoniconsGlyphMapResolvesStarOutline() {
    XCTAssertNotNil(IoniconsGlyphMap.unicode(for: "star-outline"))
  }

  func testIoniconsUnknownNameReturnsNil() {
    XCTAssertNil(IoniconsGlyphMap.unicode(for: "__not_a_real_icon__"))
  }
}
