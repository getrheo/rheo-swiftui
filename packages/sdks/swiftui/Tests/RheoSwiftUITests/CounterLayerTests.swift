import XCTest
@testable import RheoSwiftUI

final class CounterLayerTests: XCTestCase {
  func testResolveCounterAnimationDurationMsTimeModeUsesSpanSeconds() {
    XCTAssertEqual(
      resolveCounterAnimationDurationMs(
        displayKind: "time",
        durationMs: 1_800,
        startValue: 0,
        endValue: 60
      ),
      60_000
    )
  }

  func testResolveCounterAnimationDurationMsNumberModeUsesAuthoredDuration() {
    XCTAssertEqual(
      resolveCounterAnimationDurationMs(
        displayKind: "number",
        durationMs: 1_800,
        startValue: 0,
        endValue: 60
      ),
      1_800
    )
  }

  func testFormatCounterLayerDisplayTimeMmSs() {
    XCTAssertEqual(
      formatCounterLayerDisplay(0, displayKind: "time", decimalPlaces: nil, timeFormat: "mm_ss"),
      "0:00"
    )
    XCTAssertEqual(
      formatCounterLayerDisplay(60, displayKind: "time", decimalPlaces: nil, timeFormat: "mm_ss"),
      "1:00"
    )
  }

  func testFormatCounterLayerDisplayNumber() {
    XCTAssertEqual(
      formatCounterLayerDisplay(90, displayKind: "number", decimalPlaces: 0, timeFormat: nil),
      "90"
    )
  }
}
