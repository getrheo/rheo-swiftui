import SwiftUI

/// Interpolates authored clip endpoints; `progress` is animatable so SwiftUI drives the motion.
struct SampledClipAnimatableModifier: AnimatableModifier {
  var progress: Double
  var from: SampledClip
  var to: SampledClip
  var pinOpacity: Bool

  var animatableData: Double {
    get { progress }
    set { progress = newValue }
  }

  func body(content: Content) -> some View {
    let clip = lerpSampledClips(from, to, progress: progress)
    content
      .opacity(pinOpacity ? 1 : (clip.opacity ?? 1))
      .offset(x: CGFloat(clip.translateX ?? 0), y: CGFloat(clip.translateY ?? 0))
      .scaleEffect(clip.scale ?? 1)
  }
}

struct RestingMotionModifier: ViewModifier {
  var style: RestingMotionStyle
  var size: CGSize

  func body(content: Content) -> some View {
    content
      .opacity(style.opacity ?? 1)
      .offset(
        x: restingOffset(style.translateX, unit: style.translateUnit, axis: size.width),
        y: restingOffset(style.translateY, unit: style.translateUnit, axis: size.height)
      )
      .scaleEffect(style.scale ?? 1)
      .rotationEffect(.degrees(style.rotationDegrees ?? 0))
  }

  private func restingOffset(_ value: Double?, unit: RestingMotionStyle.RestingTranslateUnit, axis: CGFloat) -> CGFloat {
    guard let value else { return 0 }
    switch unit {
    case .px:
      return CGFloat(value)
    case .percent:
      return CGFloat(value) * axis / 100
    }
  }
}

func animationForEasingToken(_ token: EasingToken, duration: Double) -> Animation {
  switch token {
  case .linear:
    return .linear(duration: duration)
  case .easeIn:
    return .easeIn(duration: duration)
  case .easeOut:
    return .easeOut(duration: duration)
  case .easeInOut:
    return .easeInOut(duration: duration)
  case .standard:
    return .timingCurve(0.2, 0, 0, 1, duration: duration)
  case .emphasized:
    return .timingCurve(0.3, 0, 0, 1, duration: duration)
  }
}
