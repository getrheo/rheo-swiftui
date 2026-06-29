import SwiftUI
import XCTest
@testable import RheoSwiftUI

final class AbsoluteLayoutTests: XCTestCase {
  func testLayerHasAbsolutePositionOnStackStyle() {
    var style = CommonStyle()
    style.position = "absolute"
    let layer = StackLayer(
      id: "s1",
      name: nil,
      kind: "stack",
      style: style,
      styleBreakpoints: nil,
      stackLayoutBreakpoints: nil,
      selectedStyle: nil,
      direction: "vertical",
      gap: nil,
      align: nil,
      justify: nil,
      distribution: nil,
      wrap: nil,
      restingMotions: nil,
      children: []
    )
    XCTAssertTrue(layerHasAbsolutePositionAuthored(.stack(layer)))
  }

  func testSubtreeDetectsNestedAbsoluteChild() {
    var childStyle = CommonStyle()
    childStyle.position = "absolute"
    let child = StackLayer(
      id: "c1",
      name: nil,
      kind: "stack",
      style: childStyle,
      styleBreakpoints: nil,
      stackLayoutBreakpoints: nil,
      selectedStyle: nil,
      direction: "vertical",
      gap: nil,
      align: nil,
      justify: nil,
      distribution: nil,
      wrap: nil,
      restingMotions: nil,
      children: []
    )
    let parent = StackLayer(
      id: "p1",
      name: nil,
      kind: "stack",
      style: nil,
      styleBreakpoints: nil,
      stackLayoutBreakpoints: nil,
      selectedStyle: nil,
      direction: "vertical",
      gap: nil,
      align: nil,
      justify: nil,
      distribution: nil,
      wrap: nil,
      restingMotions: nil,
      children: [.stack(child)]
    )
    XCTAssertTrue(layerSubtreeContainsAbsolutePosition(.stack(parent)))
  }

  func testStripCommonLayoutForInnerRemovesAbsoluteKeys() {
    var style = CommonStyle()
    style.position = "absolute"
    style.inset = Padding(t: 8, r: 12)
    style.zIndex = 3
    style.rotate = 45
    style.width = .number(120)
    style.padding = Padding(t: 4)
    let inner = stripCommonLayoutForInner(style)
    XCTAssertNil(inner?.position)
    XCTAssertNil(inner?.inset)
    XCTAssertNil(inner?.zIndex)
    XCTAssertNil(inner?.rotate)
    XCTAssertNil(inner?.width)
    XCTAssertEqual(inner?.padding?.t, 4)
  }

  func testAlignmentFromInsetTopTrailing() {
    let inset = Padding(t: 8, r: 12)
    let alignment = alignmentFromInset(inset)
    XCTAssertEqual(alignment, Alignment.topTrailing)
  }

  func testAlignmentFromInsetBottomLeading() {
    let inset = Padding(b: 56, l: 12)
    let alignment = alignmentFromInset(inset)
    XCTAssertEqual(alignment, Alignment.bottomLeading)
  }

  func testAbsoluteWidthResolvedOnWrapperNotInnerChrome() {
    var style = CommonStyle()
    style.position = "absolute"
    style.width = .number(120)
    let inner = stripCommonLayoutForInner(style)
    XCTAssertNil(inner?.width)
    XCTAssertEqual(widthPoints(style.width, containerWidth: 390), 120)
  }
}
