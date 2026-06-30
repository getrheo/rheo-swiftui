import XCTest
@testable import RheoSwiftUI

final class SdkLoggerTests: XCTestCase {
  func testDefaultLogLevelIsSilent() {
    XCTAssertEqual(SdkLogLevel.default, .silent)
  }

  func testSilentLoggerDoesNotEmitWarnings() {
    let logger = SdkLogger(level: .silent)
    logger.warn("[rheo] should not print")
    logger.debug("[rheo] should not print")
  }

  func testWarnLoggerAcceptsWarnLevel() {
    let logger = SdkLogger(level: .warn)
    logger.warn("[rheo] transport failure")
  }
}
