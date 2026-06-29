import XCTest
@testable import RheoSwiftUI

/// Shared fixture parity: Swift runtime terminal paths align with RN for the same manifests.
final class TerminalParityTests: XCTestCase {
  func testMinimalFlowTerminalPathMatchesRuntimeHarness() throws {
    let manifest = try decodeFixture("minimal-flow", as: FlowManifest.self)
    var state = startFlow(initFlowState(manifest: manifest, locale: "en", platform: "ios"))
    state = submitResponse(state, response: .cta(action: "primary"))
    state = submitResponse(state, response: .cta(action: "primary"))
    XCTAssertEqual(state.status, .completed)
    XCTAssertEqual(buildCompletionResponses(state).count, 2)
  }

  func testChoiceBranchFixtureMatchesRuntimeHarness() throws {
    let manifest = try decodeFixture("stress-layers-flow", as: FlowManifest.self)
    var state = startFlow(initFlowState(manifest: manifest, locale: "en", platform: "ios"))
    state = submitResponse(state, response: .choice(choiceId: "premium"))
    XCTAssertEqual(state.currentScreenId, "scr_premium")
  }
}
