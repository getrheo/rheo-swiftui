import XCTest
@testable import RheoSwiftUI

final class OAuthPresetBrandTests: XCTestCase {
  func testGoogleLightBrandMatchesRendererCore() {
    let brand = oauthPresetBrandModel(.google, mode: .light)
    XCTAssertEqual(brand.backgroundColor, "#4285F4")
    XCTAssertEqual(brand.labelColor, "#ffffff")
    XCTAssertEqual(brand.iconColor, "#ffffff")
  }

  func testGoogleDarkBrandUsesWhiteFill() {
    let brand = oauthPresetBrandModel(.google, mode: .dark)
    XCTAssertEqual(brand.backgroundColor, "#ffffff")
    XCTAssertEqual(brand.labelColor, "#4285F4")
  }

  func testGithubPresetLabel() {
    XCTAssertEqual(
      oauthPresetEffectiveLabel(provider: .github, label: nil, locale: "en"),
      "Continue with GitHub"
    )
  }

  func testGooglePresetLabelOverrideWhenEmpty() {
    var label = LocalizedText(default: "  ")
    XCTAssertEqual(
      oauthPresetEffectiveLabel(provider: .google, label: label, locale: "en"),
      "Sign in with Google"
    )
    label = LocalizedText(default: "Workspace login")
    XCTAssertEqual(
      oauthPresetEffectiveLabel(provider: .google, label: label, locale: "en"),
      "Workspace login"
    )
  }
}
