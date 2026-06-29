import Foundation

public let screenBackgroundPlaybackPrefix = "__screen_bg__:"

public func screenBackgroundPlaybackId(screenId: String) -> String {
  "\(screenBackgroundPlaybackPrefix)\(screenId)"
}

public struct ScreenBackgroundScrim: Codable, Equatable, Sendable {
  public var color: ThemedColor?
  public var opacity: Double?
}

public enum ScreenBackgroundFillKind: String, Codable, Sendable {
  case color
  case image
  case video
}

public struct ScreenBackgroundFill: Codable, Equatable, Sendable {
  public var kind: ScreenBackgroundFillKind
  public var color: ThemedColor?
  public var media: MediaReference?
  public var fit: String?
  public var opacity: Double?
  public var scrim: ScreenBackgroundScrim?
  public var loop: Bool?
  public var autoPlay: Bool?
  public var triggerLayerId: String?
  public var onComplete: LoaderOnComplete?
  public var audioEnabled: Bool?
}

public struct ScreenContainerBreakpointPatch: Codable, Equatable, Sendable {
  public var padding: Padding?
  public var margin: Padding?
  public var insetSafeArea: Bool?
  public var backgroundFillPatch: ScreenBackgroundFillPatch?
}

public struct ScreenBackgroundFillPatch: Codable, Equatable, Sendable {
  public var color: ThemedColor?
  public var fit: String?
  public var opacity: Double?
  public var scrim: ScreenBackgroundScrim?
  public var loop: Bool?
  public var autoPlay: Bool?
  public var triggerLayerId: String?
  public var onComplete: LoaderOnComplete?
  public var audioEnabled: Bool?
}

public struct ScreenContainerStyleBreakpoints: Codable, Equatable, Sendable {
  public var sm: ScreenContainerBreakpointPatch?
  public var md: ScreenContainerBreakpointPatch?
  public var lg: ScreenContainerBreakpointPatch?
  public var xl: ScreenContainerBreakpointPatch?
  public var xl2: ScreenContainerBreakpointPatch?

  enum CodingKeys: String, CodingKey {
    case sm, md, lg, xl
    case xl2 = "2xl"
  }
}
