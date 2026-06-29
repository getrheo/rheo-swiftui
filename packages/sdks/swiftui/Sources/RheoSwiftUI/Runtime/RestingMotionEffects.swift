import Foundation

public struct RestingMotionStyle: Equatable, Sendable {
  public var opacity: Double?
  public var translateX: Double?
  public var translateY: Double?
  public var translateUnit: RestingTranslateUnit
  public var scale: Double?
  public var rotationDegrees: Double?

  public enum RestingTranslateUnit: Sendable {
    case px
    case percent
  }

  public static let identity = RestingMotionStyle(
    opacity: nil,
    translateX: nil,
    translateY: nil,
    translateUnit: .px,
    scale: nil,
    rotationDegrees: nil
  )
}

private let restingMotionBounceBasePx = 14.0
private let restingMotionDefaultScaleUpPercent = 8.0
private let restingMotionDefaultTranslatePeakYPercent = 6.0
private let restingMotionDefaultRotateDeg = 5.0
private let restingMotionPulseDipBase = 0.38

public func restingMotionIntensity(_ cfg: RestingMotion) -> Double {
  cfg.intensity ?? 1
}

public func restingMotionBounceAmplitudePx(_ cfg: RestingMotion) -> Double {
  cfg.bounceAmplitudePx ?? restingMotionBounceBasePx * restingMotionIntensity(cfg)
}

public func restingMotionScalePatternDurationMs(_ cfg: RestingMotion) -> Int {
  let def = restingMotionEffectiveDurationMs(cfg)
  guard cfg.preset == "scale" else { return def }
  if cfg.loop != true {
    return cfg.durationMs ?? cfg.scalePatternDurationMs ?? cfg.cycleDurationMs ?? def
  }
  return cfg.scalePatternDurationMs ?? cfg.cycleDurationMs ?? def
}

public func restingMotionPhase01(_ cfg: RestingMotion, localMs: Double) -> Double {
  let segment = Double(restingMotionEffectiveDurationMs(cfg))
  let cycle = Double(restingMotionCycleDurationMs(cfg))
  if segment <= 0 { return 0 }

  if cfg.preset == "scale" {
    let pattern = Double(restingMotionScalePatternDurationMs(cfg))
    if pattern <= 0 { return 0 }
    if cfg.loop == true {
      let u = localMs.truncatingRemainder(dividingBy: pattern)
      let wrapped = u < 0 ? u + pattern : u
      return wrapped / pattern
    }
    return min(1, max(0, localMs / pattern))
  }

  if cfg.loop == true, cycle > 0 {
    let u = localMs.truncatingRemainder(dividingBy: cycle)
    let wrapped = u < 0 ? u + cycle : u
    return wrapped / cycle
  }
  return min(1, max(0, localMs / segment))
}

private func restingMotionScaleDirection(_ cfg: RestingMotion) -> String {
  if cfg.scaleDirection == "down" { return "down" }
  if cfg.scaleDirection == "up" { return "up" }
  let down = cfg.scaleDownPercent ?? 0
  let up = cfg.scaleUpPercent ?? 0
  if down > 0 && up == 0 { return "down" }
  return "up"
}

private func restingMotionScalePercentResolved(_ cfg: RestingMotion) -> Double {
  if let scalePercent = cfg.scalePercent { return scalePercent }
  if restingMotionScaleDirection(cfg) == "down" {
    return cfg.scaleDownPercent ?? cfg.scaleUpPercent ?? 0
  }
  return cfg.scaleUpPercent ?? restingMotionDefaultScaleUpPercent
}

private func restingMotionScaleAmountFraction(_ cfg: RestingMotion) -> Double {
  (restingMotionScalePercentResolved(cfg) / 100) * restingMotionIntensity(cfg)
}

private func restingMotionScaleSpringBack(_ cfg: RestingMotion) -> Bool {
  cfg.scaleSpringBack != false
}

private func restingMotionScalePeakMultiplier(_ cfg: RestingMotion) -> Double {
  let amt = restingMotionScaleAmountFraction(cfg)
  return restingMotionScaleDirection(cfg) == "up" ? 1 + amt : 1 - amt
}

public func restingMotionScaleAtPhase(_ cfg: RestingMotion, phase: Double) -> Double {
  let peak = restingMotionScalePeakMultiplier(cfg)
  let p = min(1, max(0, phase))
  if !restingMotionScaleSpringBack(cfg) {
    return 1 + (peak - 1) * p
  }
  if p < 0.5 {
    return 1 + (peak - 1) * (p * 2)
  }
  let t = (p - 0.5) * 2
  return peak + (1 - peak) * t
}

private struct TranslatePeak {
  var unit: RestingMotionStyle.RestingTranslateUnit
  var x: Double
  var y: Double
}

private func restingMotionTranslateBasePeak(_ cfg: RestingMotion) -> TranslatePeak {
  let hasPercent = cfg.translatePeakXPercent != nil || cfg.translatePeakYPercent != nil
  let hasPx = cfg.translatePeakXPx != nil || cfg.translatePeakYPx != nil
  if hasPercent {
    return TranslatePeak(
      unit: .percent,
      x: cfg.translatePeakXPercent ?? 0,
      y: cfg.translatePeakYPercent ?? 0
    )
  }
  if hasPx || cfg.translateRangePx != nil {
    if hasPx {
      return TranslatePeak(
        unit: .px,
        x: cfg.translatePeakXPx ?? 0,
        y: cfg.translatePeakYPx ?? 0
      )
    }
    return TranslatePeak(unit: .px, x: 0, y: cfg.translateRangePx ?? 0)
  }
  return TranslatePeak(unit: .percent, x: 0, y: restingMotionDefaultTranslatePeakYPercent)
}

private func restingMotionTranslatePeakResolved(_ cfg: RestingMotion) -> TranslatePeak {
  let base = restingMotionTranslateBasePeak(cfg)
  let i = restingMotionIntensity(cfg)
  var x = base.x * i
  var y = base.y * i
  x = min(200, max(-200, x))
  y = min(200, max(-200, y))
  return TranslatePeak(unit: base.unit, x: x, y: y)
}

private func restingMotionTranslateSpringBack(_ cfg: RestingMotion) -> Bool {
  cfg.translateSpringBack != false
}

public func restingMotionRotateMaxDeg(_ cfg: RestingMotion) -> Double {
  let raw = (cfg.rotateMaxDeg ?? restingMotionDefaultRotateDeg) * restingMotionIntensity(cfg)
  return min(360, max(0, raw))
}

private func restingMotionRotateSpringBack(_ cfg: RestingMotion) -> Bool {
  cfg.rotateSpringBack != false
}

private func restingMotionRotateSign(_ cfg: RestingMotion) -> Double {
  cfg.rotateDirection == "counterclockwise" ? -1 : 1
}

public func restingMotionPulseMinOpacity(_ cfg: RestingMotion) -> Double {
  if let pulseMinOpacity = cfg.pulseMinOpacity {
    return min(1, max(0, pulseMinOpacity))
  }
  return min(1, max(0, 1 - restingMotionPulseDipBase * restingMotionIntensity(cfg)))
}

public func restingMotionSampleStyle(_ cfg: RestingMotion, phase: Double) -> RestingMotionStyle {
  switch cfg.preset {
  case "translate":
    let peak = restingMotionTranslatePeakResolved(cfg)
    let env = restingMotionTranslateSpringBack(cfg) ? sin(phase * .pi) : phase
    var tx = env * peak.x
    var ty = env * peak.y
    if abs(tx) < 1e-6 { tx = 0 }
    if abs(ty) < 1e-6 { ty = 0 }
    return RestingMotionStyle(
      opacity: nil,
      translateX: tx,
      translateY: ty,
      translateUnit: peak.unit == .percent ? .percent : .px,
      scale: nil,
      rotationDegrees: nil
    )
  case "bounce":
    let y = -restingMotionBounceAmplitudePx(cfg) * sin(.pi * phase)
    return RestingMotionStyle(
      opacity: nil,
      translateX: 0,
      translateY: y,
      translateUnit: .px,
      scale: nil,
      rotationDegrees: nil
    )
  case "scale":
    return RestingMotionStyle(
      opacity: nil,
      translateX: nil,
      translateY: nil,
      translateUnit: .px,
      scale: restingMotionScaleAtPhase(cfg, phase: phase),
      rotationDegrees: nil
    )
  case "pulse":
    let omin = restingMotionPulseMinOpacity(cfg)
    let dip = 1 - omin
    let op = phase <= 0.5 ? 1 - phase * 2 * dip : 1 - (1 - phase) * 2 * dip
    return RestingMotionStyle(opacity: op, translateX: nil, translateY: nil, translateUnit: .px, scale: nil, rotationDegrees: nil)
  case "rotate":
    let peakDeg = restingMotionRotateMaxDeg(cfg)
    var deg =
      restingMotionRotateSign(cfg)
      * (restingMotionRotateSpringBack(cfg) ? sin(phase * .pi) * peakDeg : phase * peakDeg)
    if abs(deg) < 1e-6 { deg = 0 }
    return RestingMotionStyle(opacity: nil, translateX: nil, translateY: nil, translateUnit: .px, scale: nil, rotationDegrees: deg)
  default:
    return .identity
  }
}

public func restingMotionStyleAtTime(
  screen: Screen,
  layerId: String,
  cfg: RestingMotion,
  tMs: Double
) -> RestingMotionStyle? {
  let start = Double(layerRestingMotionStartMs(screen, layerId: layerId, cfg: cfg))
  let end = start + Double(restingMotionEffectiveDurationMs(cfg))
  guard tMs >= start, tMs < end else { return nil }
  let local = tMs - start
  let phase = restingMotionPhase01(cfg, localMs: local)
  return restingMotionSampleStyle(cfg, phase: phase)
}

public func mergedRestingMotionStyle(
  screen: Screen,
  layerId: String,
  entries: [RestingMotion],
  tMs: Double
) -> RestingMotionStyle {
  entries.reduce(into: RestingMotionStyle.identity) { acc, entry in
    guard let sampled = restingMotionStyleAtTime(screen: screen, layerId: layerId, cfg: entry, tMs: tMs) else {
      return
    }
    if let opacity = sampled.opacity { acc.opacity = opacity }
    if let translateX = sampled.translateX { acc.translateX = (acc.translateX ?? 0) + translateX }
    if let translateY = sampled.translateY { acc.translateY = (acc.translateY ?? 0) + translateY }
    if sampled.translateUnit == .percent { acc.translateUnit = .percent }
    if let scale = sampled.scale { acc.scale = scale }
    if let rotationDegrees = sampled.rotationDegrees { acc.rotationDegrees = rotationDegrees }
  }
}
