import Foundation

public enum EasingToken: String, Codable, Sendable {
  case linear
  case easeIn = "ease-in"
  case easeOut = "ease-out"
  case easeInOut = "ease-in-out"
  case standard
  case emphasized
}

public struct ScreenStagger: Codable, Equatable, Sendable {
  public var stepMs: Int
}

public enum AnimationTrigger: String, Codable, Sendable {
  case mount
  case stagger
  case unmount
}

public enum AnimatableProperty: String, Codable, Sendable {
  case opacity
  case translateX
  case translateY
  case scale
}

public struct Keyframe: Codable, Equatable, Sendable {
  public var t: Double
  public var value: Double
  public var easing: EasingToken?
}

public struct KeyframeTrack: Codable, Equatable, Sendable {
  public var property: AnimatableProperty
  public var keyframes: [Keyframe]
}

public struct AnimationClip: Codable, Equatable, Sendable {
  public var id: String
  public var targetLayerId: String
  public var trigger: AnimationTrigger
  public var staggerIndex: Int?
  public var durationMs: Int
  public var delayMs: Int?
  public var tracks: [KeyframeTrack]
}

public struct SampledClip: Equatable, Sendable {
  public var opacity: Double?
  public var translateX: Double?
  public var translateY: Double?
  public var scale: Double?

  public init(opacity: Double? = nil, translateX: Double? = nil, translateY: Double? = nil, scale: Double? = nil) {
    self.opacity = opacity
    self.translateX = translateX
    self.translateY = translateY
    self.scale = scale
  }
}
