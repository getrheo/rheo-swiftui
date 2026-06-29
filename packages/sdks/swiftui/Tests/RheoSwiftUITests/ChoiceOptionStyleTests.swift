import XCTest
@testable import RheoSwiftUI

final class ChoiceOptionStyleTests: XCTestCase {
  func testStackWithSelectedStyleMergesResolvedDefaultAndSelected() {
    var base = CommonStyle()
    base.background = .raw("#111111")
    base.radius = 4
    var selected = CommonStyle()
    selected.background = .raw("#ff0000")
    selected.radius = 12
    let stack = StackLayer(
      id: "opt",
      name: nil,
      kind: "stack",
      style: base,
      styleBreakpoints: nil,
      stackLayoutBreakpoints: nil,
      selectedStyle: selected,
      direction: "vertical",
      gap: nil,
      align: nil,
      justify: nil,
      distribution: nil,
      wrap: nil,
      restingMotions: nil,
      children: []
    )
    let merged = stackWithSelectedStyle(stack, isSelected: true, widthPx: 390)
    XCTAssertEqual(merged.style?.background, .raw("#ff0000"))
    XCTAssertEqual(merged.style?.radius, 12)
    XCTAssertNil(merged.styleBreakpoints)
  }

  func testStackWithSelectedStyleLeavesStackWhenNotSelected() {
    let stack = StackLayer(
      id: "opt",
      name: nil,
      kind: "stack",
      style: CommonStyle(),
      styleBreakpoints: nil,
      stackLayoutBreakpoints: nil,
      selectedStyle: CommonStyle(),
      direction: "vertical",
      gap: nil,
      align: nil,
      justify: nil,
      distribution: nil,
      wrap: nil,
      restingMotions: nil,
      children: []
    )
    let out = stackWithSelectedStyle(stack, isSelected: false, widthPx: 390)
    XCTAssertEqual(out.id, stack.id)
    XCTAssertNotNil(out.selectedStyle)
  }

  func testChoiceOptionHasAuthoredLookDetectsSelectedStyleOnly() {
    let stack = StackLayer(
      id: "opt",
      name: nil,
      kind: "stack",
      style: nil,
      styleBreakpoints: nil,
      stackLayoutBreakpoints: nil,
      selectedStyle: CommonStyle(),
      direction: "vertical",
      gap: nil,
      align: nil,
      justify: nil,
      distribution: nil,
      wrap: nil,
      restingMotions: nil,
      children: []
    )
    XCTAssertTrue(choiceOptionHasAuthoredLook(stack))
  }
}
