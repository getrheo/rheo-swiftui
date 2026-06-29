import XCTest
@testable import RheoSwiftUI

final class RendererModelTests: XCTestCase {
  func testButtonPaletteMatchesNativeDefaults() {
    XCTAssertEqual(buttonPalette("primary", mode: .light).background, "#0a0a0a")
    XCTAssertEqual(buttonPalette("primary", mode: .dark).background, "#fafafa")
    XCTAssertEqual(buttonPalette("secondary", mode: .light).border, "#e4e4e7")
  }

  func testResolveSurfaceBackgroundSkipsWhenUnset() {
    XCTAssertNil(resolveSurfaceBackground(nil, theme: nil, mode: .light))
    XCTAssertNil(resolveSurfaceBackground(nil, theme: nil, mode: .dark))
    XCTAssertNil(resolveSurfaceBackground(.modes(light: nil, dark: nil), theme: nil, mode: .light))
    XCTAssertFalse(resolveSurfaceFill(.modes(light: nil, dark: nil), theme: nil, branding: nil, mode: .light).hasAuthoredFill)
  }

  func testResolveColorWithoutFallbackIsClear() {
    XCTAssertEqual(resolveColor(nil, theme: nil, mode: .light), .clear)
    XCTAssertEqual(resolveColor(nil, theme: nil, mode: .dark), .clear)
  }

  func testResolveSurfaceBackgroundPicksMode() {
    let themed = ThemedColor.modes(light: "#ffffff", dark: "#0a0a0a")
    XCTAssertEqual(resolveColorString(themed, theme: nil, mode: .light), "#ffffff")
    XCTAssertEqual(resolveColorString(themed, theme: nil, mode: .dark), "#0a0a0a")
    XCTAssertNotNil(resolveSurfaceBackground(themed, theme: nil, mode: .light))
  }

  func testColorFromCssStringParsesRgb() {
    XCTAssertNotNil(colorFromCssString("rgb(34, 197, 94)"))
  }

  func testScreenContainerFallbackIsPureBlackAndWhite() {
    XCTAssertEqual(screenContainerFallbackColor(for: .dark), .black)
    XCTAssertEqual(screenContainerFallbackColor(for: .light), .white)
  }

  func testResolveScreenContainerStyleAtWidthMergesPaddingBreakpoints() {
    var breakpoints = ScreenContainerStyleBreakpoints()
    breakpoints.md = ScreenContainerBreakpointPatch(padding: Padding(t: 12, r: 12, b: 12, l: 12))
    let resolved = resolveScreenContainerStyleAtWidth(
      ScreenContainerStyle(padding: Padding(t: 8, r: 8, b: 8, l: 8)),
      breakpoints,
      width: 800
    )
    XCTAssertEqual(resolved?.padding?.t, 12)
    XCTAssertEqual(resolved?.padding?.r, 12)
  }

  func testResolveScreenContainerStyleAtWidthMergesInsetSafeAreaBreakpoints() {
    var breakpoints = ScreenContainerStyleBreakpoints()
    breakpoints.md = ScreenContainerBreakpointPatch(insetSafeArea: true)
    let resolved = resolveScreenContainerStyleAtWidth(
      ScreenContainerStyle(insetSafeArea: false),
      breakpoints,
      width: 800
    )
    XCTAssertEqual(resolved?.insetSafeArea, true)
  }

  func testAddPaddingMergesShellInsets() {
    XCTAssertEqual(addPadding(Padding(t: 8), Padding(t: 20, b: 34))?.t, 28)
    XCTAssertEqual(addPadding(Padding(t: 8), Padding(t: 20, b: 34))?.b, 34)
  }

  func testEffectiveThemeModeFollowsSystemWhenUnset() {
    XCTAssertEqual(effectiveThemeMode(explicit: nil, colorScheme: .light), .light)
    XCTAssertEqual(effectiveThemeMode(explicit: nil, colorScheme: .dark), .dark)
    XCTAssertEqual(effectiveThemeMode(explicit: .dark, colorScheme: .light), .dark)
  }

  func testDropShadowHasAnyField() {
    XCTAssertFalse(dropShadowHasAnyField(nil))
    XCTAssertFalse(dropShadowHasAnyField(DropShadow()))
    XCTAssertTrue(dropShadowHasAnyField(DropShadow(blur: 8)))
  }

  func testResolveDropShadowColorUsesOpacity() {
    let shadow = DropShadow(color: .raw("#ff0000"), opacity: 0.5)
    let color = resolveDropShadowColor(shadow, theme: nil, mode: .light)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
    XCTAssertEqual(r, 1, accuracy: 0.01)
    XCTAssertEqual(a, 0.5, accuracy: 0.01)
  }

  func testCommonStyleWithoutBackgroundDoesNotCreateSurfaceChrome() {
    XCTAssertFalse(CommonStyle().hasSurfaceChrome)
  }

  func testCommonStyleWithAuthoredBackgroundCreatesSurfaceChrome() {
    var base = CommonStyle()
    base.background = .raw("#ffffff")

    XCTAssertTrue(base.hasSurfaceChrome)
  }

  func testScreenShellBackdropUsesAuthoredBackground() {
    var screen = Screen(
      id: "s1",
      name: "Welcome",
      regions: ScreenRegions(
        header: nil,
        body: StackLayer(
          id: "body",
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
          children: []
        ),
        footer: nil
      ),
      next: ScreenNext(default: nil),
      animations: nil,
      stagger: nil,
      containerStyle: nil,
      containerStyleBreakpoints: nil
    )
    screen.containerStyle = ScreenContainerStyle(
      backgroundFill: ScreenBackgroundFill(kind: .color, color: .raw("#00ff00"))
    )

    let bgFill = resolveScreenBackgroundFillAtWidth(screen, width: 390)
    XCTAssertEqual(bgFill?.kind, .color)
    XCTAssertEqual(bgFill?.color, .raw("#00ff00"))
    XCTAssertEqual(resolveColorString(.raw("#00ff00"), theme: nil, mode: .light), "#00ff00")
    XCTAssertEqual(
      screenShellBackdropColor(screen, theme: nil, branding: nil, mode: .light, width: 390),
      resolveSurfaceBackground(.raw("#00ff00"), theme: nil, mode: .light)
    )
  }

  func testScreenShellBackdropNilWithoutAuthoredBackground() {
    let screen = Screen(
      id: "s1",
      name: "Welcome",
      regions: ScreenRegions(
        header: nil,
        body: StackLayer(
          id: "body",
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
          children: []
        ),
        footer: nil
      ),
      next: ScreenNext(default: nil),
      animations: nil,
      stagger: nil,
      containerStyle: nil,
      containerStyleBreakpoints: nil
    )

    XCTAssertFalse(resolveScreenShellFill(screen, theme: nil, branding: nil, mode: .light, width: 390).hasAuthoredFill)
    XCTAssertNil(screenShellBackdropColor(screen, theme: nil, branding: nil, mode: .light, width: 390))
    XCTAssertEqual(
      screenShellBackdropResolvedColor(screen, theme: nil, branding: nil, mode: .light, width: 390),
      screenContainerFallbackColor(for: .light)
    )
    XCTAssertEqual(
      screenShellBackdropResolvedColor(screen, theme: nil, branding: nil, mode: .dark, width: 390),
      screenContainerFallbackColor(for: .dark)
    )
  }

  func testScreenShellBackdropUsesAuthoredShellBackground() {
    var screen = Screen(
      id: "s1",
      name: "Welcome",
      regions: ScreenRegions(
        header: nil,
        body: StackLayer(
          id: "body",
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
          children: []
        ),
        footer: nil
      ),
      next: ScreenNext(default: nil),
      animations: nil,
      stagger: nil,
      containerStyle: nil,
      containerStyleBreakpoints: nil
    )
    screen.containerStyle = ScreenContainerStyle(
      backgroundFill: ScreenBackgroundFill(kind: .color, color: .raw("#00ff00"))
    )

    XCTAssertEqual(
      resolveScreenBackgroundFillAtWidth(screen, width: 390)?.color,
      .raw("#00ff00")
    )
  }
}
