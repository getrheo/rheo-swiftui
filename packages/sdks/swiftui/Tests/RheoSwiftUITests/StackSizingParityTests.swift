import SwiftUI
import XCTest
@testable import RheoSwiftUI

/// Sizing-parity tests for the SwiftUI stack/button shells. Mirrors the Web/RN
/// parity model (Option A: nested stacks fill the parent main axis
/// unconditionally) and the button outer-shell convergence (R9).
final class StackSizingParityTests: XCTestCase {
  func testNestedMainAxisFillConstructsForVerticalParent() {
    let modifier = StackNestedMainAxisFill(parentDirection: .vertical)
    XCTAssertEqual(modifier.parentDirection, .vertical)
  }

  func testNestedMainAxisFillConstructsForHorizontalParent() {
    let modifier = StackNestedMainAxisFill(parentDirection: .horizontal)
    XCTAssertEqual(modifier.parentDirection, .horizontal)
  }

  func testNestedMainAxisFillConstructsForNoParent() {
    let modifier = StackNestedMainAxisFill(parentDirection: nil)
    XCTAssertNil(modifier.parentDirection)
  }

  // R9: a button's own outer-shell style (margin, position, inset, zIndex,
  // rotate) must survive the conversion that feeds `rheoWrapperLayout`.
  func testButtonStyleAsCommonStyleCarriesOuterShellFields() {
    var style = ButtonStyle()
    style.margin = Padding(t: 4, r: 5, b: 6, l: 7)
    style.position = "absolute"
    style.inset = Padding(t: 1, r: 2, b: 3, l: 8)
    style.zIndex = 9
    style.rotate = 12

    let common = style.asCommonStyle
    XCTAssertEqual(common.margin, Padding(t: 4, r: 5, b: 6, l: 7))
    XCTAssertEqual(common.position, "absolute")
    XCTAssertEqual(common.inset, Padding(t: 1, r: 2, b: 3, l: 8))
    XCTAssertEqual(common.zIndex, 9)
    XCTAssertEqual(common.rotate, 12)
  }
}
