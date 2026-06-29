import SwiftUI
import XCTest
@testable import RheoSwiftUI

/// Behavioural tests for the SwiftUI flex-shell model. Mirrors the parity
/// matrix for web `flowChildLayoutCss` and React Native
/// `flowChildLayoutViewStyle`.
final class FlowChildLayoutTests: XCTestCase {
  func testParentStackDirectionDefaultsToNil() {
    let env = EnvironmentValues()
    XCTAssertNil(env.rheoParentStackDirection)
  }

  func testParentStackDirectionCanBeSetToVertical() {
    var env = EnvironmentValues()
    env.rheoParentStackDirection = .vertical
    XCTAssertEqual(env.rheoParentStackDirection, .vertical)
  }

  func testParentStackDirectionCanBeSetToHorizontal() {
    var env = EnvironmentValues()
    env.rheoParentStackDirection = .horizontal
    XCTAssertEqual(env.rheoParentStackDirection, .horizontal)
  }

  func testFlowChildLayoutModifierConstructsForFullWidth() {
    // Smoke test: constructing the modifier with each canonical input must
    // succeed without crashing. SwiftUI internals own actual rendering;
    // here we just verify the modifier accepts the value shapes used by
    // the renderer.
    var style = CommonStyle()
    style.width = .preset("full")
    let modifier = RheoFlowChildLayout(resolved: style)
    XCTAssertEqual(modifier.resolved?.width, .preset("full"))
  }

  func testFlowChildLayoutModifierConstructsForFillHeight() {
    var style = CommonStyle()
    style.height = .preset("fill")
    let modifier = RheoFlowChildLayout(resolved: style)
    XCTAssertEqual(modifier.resolved?.height, .preset("fill"))
  }

  func testFlowChildLayoutModifierConstructsForAbsoluteLayer() {
    var style = CommonStyle()
    style.position = "absolute"
    style.width = .preset("full")
    let modifier = RheoFlowChildLayout(resolved: style)
    XCTAssertEqual(modifier.resolved?.position, "absolute")
  }

  func testFlowChildLayoutModifierConstructsWithNoStyle() {
    let modifier = RheoFlowChildLayout(resolved: nil)
    XCTAssertNil(modifier.resolved)
  }
}
