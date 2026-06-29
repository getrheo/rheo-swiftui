import SwiftUI

private struct LayerSizePreferenceKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
    let next = nextValue()
    if next.width > 0, next.height > 0 { value = next }
  }
}

struct LayerMotionShell<Content: View>: View {
  var layer: Layer
  @ViewBuilder var content: () -> Content
  @Environment(\.motionController) private var motion
  @State private var mountProgress: Double = 1
  @State private var unmountProgress: Double = 0
  @State private var mountAnchor = Date()
  @State private var layerSize: CGSize = .zero

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
      let elapsedMs = timeline.date.timeIntervalSince(mountAnchor) * 1_000
      let mountSamples = self.mountSamples
      let unmountSamples = self.unmountSamples
      let resting = restingStyle(elapsedMs: elapsedMs)

      content()
        .background(
          GeometryReader { geo in
            Color.clear.preference(key: LayerSizePreferenceKey.self, value: geo.size)
          }
        )
        .onPreferenceChange(LayerSizePreferenceKey.self) { layerSize = $0 }
        .modifier(SampledClipAnimatableModifier(
          progress: mountSamples == nil ? 1 : mountProgress,
          from: mountSamples?.from ?? SampledClip(opacity: 1, translateX: 0, translateY: 0, scale: nil),
          to: mountSamples?.to ?? SampledClip(opacity: 1, translateX: 0, translateY: 0, scale: nil),
          pinOpacity: false
        ))
        .modifier(SampledClipAnimatableModifier(
          progress: unmountSamples == nil ? 0 : unmountProgress,
          from: unmountSamples?.from ?? SampledClip(opacity: 1, translateX: 0, translateY: 0, scale: nil),
          to: unmountSamples?.to ?? SampledClip(opacity: 1, translateX: 0, translateY: 0, scale: nil),
          pinOpacity: false
        ))
        .modifier(RestingMotionModifier(style: resting, size: layerSize))
    }
    .onAppear {
      mountAnchor = Date()
      mountProgress = initialMountProgress
    }
    .task(id: mountTaskKey) {
      mountAnchor = Date()
      await runMountProgress()
    }
  }

  private var mountTaskKey: String {
    "\(motion?.screen.id ?? "_")|\(layer.id)"
  }

  private var initialMountProgress: Double {
    guard let clip = mountClip else { return 1 }
    return clip.durationMs <= 0 ? 1 : 0
  }

  private var mountClip: AnimationClip? {
    guard let motion else { return nil }
    return pickMountClip(clipsForLayer(motion.screen, layerId: layer.id))
  }

  private var unmountClip: AnimationClip? {
    guard let motion else { return nil }
    return pickUnmountClip(clipsForLayer(motion.screen, layerId: layer.id))
  }

  private var mountSamples: (from: SampledClip, to: SampledClip)? {
    guard let motion, let clip = mountClip else { return nil }
    let end = Double(effectiveDelayMs(clip, screen: motion.screen)) + Double(max(1, clip.durationMs))
    return (
      sampleClipAt(clip, screen: motion.screen, timeMs: 0),
      sampleClipAt(clip, screen: motion.screen, timeMs: end)
    )
  }

  private var unmountSamples: (from: SampledClip, to: SampledClip)? {
    guard let motion, let clip = unmountClip else { return nil }
    let end = Double(effectiveDelayMs(clip, screen: motion.screen)) + Double(max(1, clip.durationMs))
    return (
      sampleClipAt(clip, screen: motion.screen, timeMs: 0),
      sampleClipAt(clip, screen: motion.screen, timeMs: end)
    )
  }

  private var restingMotions: [RestingMotion] {
    layerRestingMotionEntries(for: layer)
  }

  private func restingStyle(elapsedMs: Double) -> RestingMotionStyle {
    guard let motion, !restingMotions.isEmpty else {
      return .identity
    }
    return mergedRestingMotionStyle(
      screen: motion.screen,
      layerId: layer.id,
      entries: restingMotions,
      tMs: elapsedMs
    )
  }

  @MainActor
  private func runMountProgress() async {
    guard let motion else {
      mountProgress = 1
      unmountProgress = 0
      return
    }
    guard let clip = mountClip else {
      mountProgress = 1
      unmountProgress = 0
      return
    }

    mountProgress = 0
    unmountProgress = 0
    if clip.durationMs <= 0 {
      mountProgress = 1
      return
    }
    let delayNs = UInt64(max(0, effectiveDelayMs(clip, screen: motion.screen))) * 1_000_000
    let durationSec = Double(clip.durationMs) / 1_000
    let easing = clip.tracks.first?.keyframes.first?.easing ?? .standard
    if delayNs > 0 {
      try? await Task.sleep(nanoseconds: delayNs)
    }
    withAnimation(animationForEasingToken(easing, duration: durationSec)) {
      mountProgress = 1
    }
  }
}
