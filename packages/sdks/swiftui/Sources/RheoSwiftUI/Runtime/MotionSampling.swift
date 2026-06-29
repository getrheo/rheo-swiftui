import Foundation

/// Layer clip sampling. Screen transitions are not supported (instant navigation).

public func sampleClipAt(_ clip: AnimationClip, screen: Screen, timeMs: Double) -> SampledClip {
  var sampled = SampledClip()
  let delay = Double(effectiveDelayMs(clip, screen: screen))
  let duration = max(1, Double(clip.durationMs))
  let progress = min(1, max(0, (timeMs - delay) / duration))
  for track in clip.tracks {
    let value = sampleTrack(track, progress: progress)
    switch track.property {
    case .opacity: sampled.opacity = value
    case .translateX: sampled.translateX = value
    case .translateY: sampled.translateY = value
    case .scale: sampled.scale = value
    }
  }
  return sampled
}

public func effectiveDelayMs(_ clip: AnimationClip, screen: Screen) -> Int {
  let base = clip.delayMs ?? 0
  if clip.trigger == .stagger {
    return base + (clip.staggerIndex ?? 0) * (screen.stagger?.stepMs ?? 60)
  }
  return base
}

private let easingBeziers: [EasingToken: (Double, Double, Double, Double)] = [
  .linear: (0, 0, 1, 1),
  .easeIn: (0.42, 0, 1, 1),
  .easeOut: (0, 0, 0.58, 1),
  .easeInOut: (0.42, 0, 0.58, 1),
  .standard: (0.2, 0, 0, 1),
  .emphasized: (0.3, 0, 0, 1),
]

private func sampleTrack(_ track: KeyframeTrack, progress: Double) -> Double {
  let frames = track.keyframes.sorted { $0.t < $1.t }
  guard let first = frames.first else { return 0 }
  if progress <= first.t { return first.value }
  if progress >= frames.last!.t { return frames.last!.value }
  var prev = first
  var next = frames.last!
  for i in 0..<(frames.count - 1) {
    if frames[i].t <= progress && frames[i + 1].t >= progress {
      prev = frames[i]
      next = frames[i + 1]
      break
    }
  }
  let span = max(0.000001, next.t - prev.t)
  let localT = (progress - prev.t) / span
  let eased = sampleBezier(localT, easingBeziers[prev.easing ?? .linear] ?? easingBeziers[.linear]!)
  return prev.value + (next.value - prev.value) * eased
}

private func sampleBezier(_ t: Double, _ control: (Double, Double, Double, Double)) -> Double {
  let (x1, y1, x2, y2) = control
  if x1 == y1 && x2 == y2 { return t }
  let ax = 3 * x1 - 3 * x2 + 1
  let bx = 3 * x2 - 6 * x1
  let cx = 3 * x1
  let ay = 3 * y1 - 3 * y2 + 1
  let by = 3 * y2 - 6 * y1
  let cy = 3 * y1
  func xAt(_ s: Double) -> Double { ((ax * s + bx) * s + cx) * s }
  func yAt(_ s: Double) -> Double { ((ay * s + by) * s + cy) * s }
  func dxAt(_ s: Double) -> Double { (3 * ax * s + 2 * bx) * s + cx }
  var s = t
  for _ in 0..<8 {
    let x = xAt(s) - t
    let dx = dxAt(s)
    if abs(x) < 1e-6 { return yAt(s) }
    if abs(dx) < 1e-6 { break }
    s -= x / dx
  }
  var lo = 0.0
  var hi = 1.0
  s = t
  for _ in 0..<24 {
    let x = xAt(s)
    if abs(x - t) < 1e-6 { return yAt(s) }
    if x < t { lo = s } else { hi = s }
    s = (lo + hi) / 2
  }
  return yAt(s)
}
