import UIKit
import XCTest
@testable import RheoSwiftUI

final class OAuthPresetImageLoaderTests: XCTestCase {
  func testBundledGithubLogoLoads() {
    XCTAssertNotNil(OAuthPresetImageLoader.uiImage(named: "logo-github"))
  }

  func testBundledGoogleLogoLoads() {
    XCTAssertNotNil(OAuthPresetImageLoader.uiImage(named: "logo-google"))
  }

  func testBundledLogosHaveNonZeroSize() {
    let github = OAuthPresetImageLoader.uiImage(named: "logo-github")
    XCTAssertGreaterThan(github?.size.width ?? 0, 0)
    XCTAssertGreaterThan(github?.size.height ?? 0, 0)
  }
}
