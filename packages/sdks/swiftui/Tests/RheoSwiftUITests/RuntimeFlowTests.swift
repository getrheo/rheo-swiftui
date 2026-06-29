import XCTest
@testable import RheoSwiftUI

final class RuntimeFlowTests: XCTestCase {
  func testLinearFlowCompletes() throws {
    let manifest = try decodeFixture("minimal-flow", as: FlowManifest.self)
    var state = startFlow(initFlowState(manifest: manifest, locale: "en", platform: "ios"))
    XCTAssertEqual(state.currentScreenId, "scr_start")
    state = submitResponse(state, response: .cta(action: "primary"))
    XCTAssertEqual(state.currentScreenId, "scr_done")
    state = submitResponse(state, response: .cta(action: "primary"))
    XCTAssertEqual(state.status, .completed)
  }

  func testChoiceBranching() throws {
    let manifest = try decodeFixture("stress-layers-flow", as: FlowManifest.self)
    var state = startFlow(initFlowState(manifest: manifest, locale: "en", platform: "ios"))
    state = submitResponse(state, response: .choice(choiceId: "premium"))
    XCTAssertEqual(state.currentScreenId, "scr_premium")
  }

  func testTerminalSnapshotIncludesNullUnansweredFields() throws {
    let manifest = try decodeFixture("stress-layers-flow", as: FlowManifest.self)
    let resolved = SdkResolveResponse(
      flowId: manifest.flowId,
      versionId: "00000000-0000-4000-8000-000000000010",
      versionNumber: 1,
      assignmentVersion: 0,
      environment: "test",
      channelId: "ch_test_fixture",
      experimentId: nil,
      variantId: nil,
      manifest: manifest,
      mediaMap: [:],
      branding: nil,
      features: nil,
      integrations: ResolvedAppIntegrations(appsflyer: nil, revenuecat: nil, raw: [:])
    )
    var state = startFlow(initFlowState(manifest: manifest, locale: "en", platform: "ios"))
    state = abandonFlow(state)
    let snapshot = buildTerminalSnapshot(
      terminal: "abandoned",
      resolved: resolved,
      state: state,
      subject: SdkIdentity(appUserId: "u1", customUserId: nil, sessionId: nil),
      appVersion: nil,
      customProperties: [:],
      includeManifest: false,
      includePath: true,
      includeAnswerDetail: false
    )
    XCTAssertEqual(snapshot.answers["tier"], .null)
    XCTAssertEqual(snapshot.path, ["scr_inputs"])
  }
}
