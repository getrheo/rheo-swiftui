import XCTest
@testable import RheoSwiftUI

final class MotionClipHelpersTests: XCTestCase {
  func testPickMountClipPrefersMountOverStagger() {
    let mount = AnimationClip(
      id: "m",
      targetLayerId: "lyr_a",
      trigger: .mount,
      staggerIndex: nil,
      durationMs: 400,
      delayMs: nil,
      tracks: []
    )
    let stagger = AnimationClip(
      id: "s",
      targetLayerId: "lyr_a",
      trigger: .stagger,
      staggerIndex: 1,
      durationMs: 300,
      delayMs: nil,
      tracks: []
    )
    XCTAssertEqual(pickMountClip([stagger, mount])?.id, "m")
  }

  func testSampleClipAtFadeIn() {
    let screen = Screen(
      id: "scr",
      name: "Motion",
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
      animations: [
        AnimationClip(
          id: "clip",
          targetLayerId: "lyr_a",
          trigger: .mount,
          staggerIndex: nil,
          durationMs: 400,
          delayMs: nil,
          tracks: [
            KeyframeTrack(
              property: .opacity,
              keyframes: [
                Keyframe(t: 0, value: 0, easing: .standard),
                Keyframe(t: 1, value: 1, easing: nil),
              ]
            ),
          ]
        ),
      ],
      stagger: nil,
      containerStyle: nil,
      containerStyleBreakpoints: nil
    )
    let start = sampleClipAt(screen.animations![0], screen: screen, timeMs: 0)
    let end = sampleClipAt(screen.animations![0], screen: screen, timeMs: 400)
    XCTAssertEqual(start.opacity, 0)
    XCTAssertEqual(end.opacity, 1)
  }

  func testLayerRestingMotionStartMsAfterMountClips() {
    let screen = Screen(
      id: "scr",
      name: "Motion",
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
      animations: [
        AnimationClip(
          id: "clip",
          targetLayerId: "lyr_a",
          trigger: .mount,
          staggerIndex: nil,
          durationMs: 500,
          delayMs: 100,
          tracks: []
        ),
      ],
      stagger: nil,
      containerStyle: nil,
      containerStyleBreakpoints: nil
    )
    let cfg = RestingMotion(id: "r", preset: "pulse", durationMs: 800, delayMsAfterMountEnd: 50)
    XCTAssertEqual(layerRestingMotionStartMs(screen, layerId: "lyr_a", cfg: cfg), 650)
  }

  func testRestingMotionFadePulsePhase() {
    let cfg = RestingMotion(id: "p", preset: "pulse", durationMs: 1000)
    let mid = restingMotionSampleStyle(cfg, phase: 0.5)
    XCTAssertLessThan(mid.opacity ?? 1, 1)
    XCTAssertGreaterThan(mid.opacity ?? 0, 0)
  }

  func testRestingMotionBouncePeak() {
    let cfg = RestingMotion(id: "b", preset: "bounce", bounceAmplitudePx: 10)
    let peak = restingMotionSampleStyle(cfg, phase: 0.5)
    XCTAssertLessThan(peak.translateY ?? 0, 0)
  }

}
