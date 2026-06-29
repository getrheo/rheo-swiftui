import XCTest
@testable import RheoSwiftUI

final class PermissionParityTests: XCTestCase {
  func testUnsupportedKeysReturnDenied() async {
    let unsupported: [OSPermissionKey] = [
      "location_when_in_use",
      "app_tracking_transparency",
      "sms_android",
      "phone_android",
      "full_screen_intent_android",
    ]
    for key in unsupported {
      let outcome = await OSPermissionRequester.request(key)
      XCTAssertEqual(outcome, .denied, "Expected denied for \(key)")
    }
  }
}
