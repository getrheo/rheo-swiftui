import XCTest
@testable import RheoSwiftUI

final class EventQueueTests: XCTestCase {
  func testBuildSdkEventIncludesIdentityAndContext() {
    let config = RheoConfig(
      publishableKey: "ob_pk_test_fixture",
      userId: "user_1",
      customUserId: "crm_1",
      sessionId: "sess_1",
      locale: "en",
      appVersion: "1.0.0",
      customProperties: ["plan": "pro"]
    )
    let event = buildSdkEvent(
      config: config,
      input: TrackEventInput(
        name: .flowStarted,
        flowId: "00000000-0000-4000-8000-000000000001",
        versionId: "00000000-0000-4000-8000-000000000002"
      )
    )
    XCTAssertEqual(event.identity.appUserId, "user_1")
    XCTAssertEqual(event.identity.customUserId, "crm_1")
    XCTAssertEqual(event.context?.locale, "en")
    XCTAssertEqual(event.context?.customProperties?["plan"], JSONValue.string("pro"))
  }
}
