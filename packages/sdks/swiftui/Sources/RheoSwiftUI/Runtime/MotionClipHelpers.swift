import Foundation

public let defaultAnimationClipDurationMs = 500
public let legacyRestingMotionId = "__legacy"

public func clipsByLayerId(_ screen: Screen) -> [String: [AnimationClip]] {
  var map: [String: [AnimationClip]] = [:]
  guard let animations = screen.animations else { return map }
  for clip in animations {
    map[clip.targetLayerId, default: []].append(clip)
  }
  return map
}

public func clipsForLayer(_ screen: Screen, layerId: String) -> [AnimationClip] {
  clipsByLayerId(screen)[layerId] ?? []
}

public func pickMountClip(_ list: [AnimationClip]) -> AnimationClip? {
  list.first { $0.trigger == .mount } ?? list.first { $0.trigger == .stagger }
}

public func pickUnmountClip(_ list: [AnimationClip]) -> AnimationClip? {
  list.first { $0.trigger == .unmount }
}

public func layerRestingMotionEntries(for layer: Layer) -> [RestingMotion] {
  let list = layerRestingMotionsRaw(layer)
  if !list.isEmpty { return list }
  return []
}

public func layerMountClipsEndMs(_ screen: Screen, layerId: String) -> Int {
  let clips = clipsForLayer(screen, layerId: layerId).filter { $0.trigger == .mount || $0.trigger == .stagger }
  return clips.map { effectiveDelayMs($0, screen: screen) + $0.durationMs }.max() ?? 0
}

public func layerRestingMotionStartMs(_ screen: Screen, layerId: String, cfg: RestingMotion) -> Int {
  if let timelineStartMs = cfg.timelineStartMs { return timelineStartMs }
  return layerMountClipsEndMs(screen, layerId: layerId) + (cfg.delayMsAfterMountEnd ?? 0)
}

public func restingMotionEffectiveDurationMs(_ cfg: RestingMotion) -> Int {
  if let durationMs = cfg.durationMs { return durationMs }
  switch cfg.preset {
  case "translate": return 2400
  case "bounce": return 2000
  case "scale": return 2200
  case "pulse": return 1800
  case "rotate": return 3200
  default: return 2000
  }
}

public func restingMotionCycleDurationMs(_ cfg: RestingMotion) -> Int {
  cfg.cycleDurationMs ?? restingMotionEffectiveDurationMs(cfg)
}

public func lerpOptional(_ a: Double?, _ b: Double?, _ p: Double) -> Double? {
  if a == nil && b == nil { return nil }
  let av = a ?? b ?? 0
  let bv = b ?? a ?? 0
  return av + (bv - av) * p
}

public func lerpSampledClips(_ from: SampledClip, _ to: SampledClip, progress: Double) -> SampledClip {
  SampledClip(
    opacity: lerpOptional(from.opacity, to.opacity, progress),
    translateX: lerpOptional(from.translateX, to.translateX, progress),
    translateY: lerpOptional(from.translateY, to.translateY, progress),
    scale: lerpOptional(from.scale, to.scale, progress)
  )
}

private func layerRestingMotionsRaw(_ layer: Layer) -> [RestingMotion] {
  switch layer {
  case .stack(let layer): return layer.restingMotions ?? []
  case .text(let layer): return layer.restingMotions ?? []
  case .hyperlink(let layer): return layer.restingMotions ?? []
  case .image(let layer): return layer.restingMotions ?? []
  case .lottie(let layer): return layer.restingMotions ?? []
  case .video(let layer): return layer.restingMotions ?? []
  case .icon(let layer): return layer.restingMotions ?? []
  case .button(let layer): return layer.restingMotions ?? []
  case .backButton(let layer): return layer.restingMotions ?? []
  case .progress(let layer): return layer.restingMotions ?? []
  case .loader(let layer): return layer.restingMotions ?? []
  case .counter(let layer): return layer.restingMotions ?? []
  case .checkbox(let layer): return layer.restingMotions ?? []
  case .singleChoice(let layer): return layer.restingMotions ?? []
  case .multipleChoice(let layer): return layer.restingMotions ?? []
  case .textInput(let layer): return layer.restingMotions ?? []
  case .scaleInput(let layer): return layer.restingMotions ?? []
  case .oauthLogin(let layer): return layer.restingMotions ?? []
  case .emailPasswordAuth(let layer): return layer.restingMotions ?? []
  default: return []
  }
}
