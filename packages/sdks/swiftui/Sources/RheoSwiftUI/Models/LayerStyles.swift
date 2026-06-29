import Foundation

public enum ThemeMode: String, Codable, Sendable {
  case light
  case dark
}

public enum ThemedColor: Codable, Equatable, Sendable {
  case raw(String)
  case modes(light: String?, dark: String?)

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let raw = try? container.decode(String.self) {
      self = .raw(raw)
      return
    }
    let modes = try container.decode(Modes.self)
    self = .modes(light: modes.light, dark: modes.dark)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .raw(let value):
      try container.encode(value)
    case .modes(let light, let dark):
      try container.encode(Modes(light: light, dark: dark))
    }
  }

  public func resolve(_ mode: ThemeMode) -> String? {
    switch self {
    case .raw(let value):
      return value
    case .modes(let light, let dark):
      return mode == .dark ? (dark ?? light) : (light ?? dark)
    }
  }

  private struct Modes: Codable {
    var light: String?
    var dark: String?
  }
}

public let defaultThemedForeground = ThemedColor.modes(light: "#0a0a0a", dark: "#fafafa")
public let primaryFilledLabel = ThemedColor.raw("#ffffff")

public struct Padding: Codable, Equatable, Sendable {
  public var t: Double? = nil
  public var r: Double? = nil
  public var b: Double? = nil
  public var l: Double? = nil
}

public struct Border: Codable, Equatable, Sendable {
  public var width: Double? = nil
  public var color: ThemedColor? = nil
}

public struct DropShadow: Codable, Equatable, Sendable {
  public var offsetX: Double? = nil
  public var offsetY: Double? = nil
  public var blur: Double? = nil
  public var spread: Double? = nil
  public var color: ThemedColor? = nil
  public var opacity: Double? = nil
}

public enum WidthValue: Codable, Equatable, Sendable {
  case number(Double)
  case preset(String)

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let n = try? container.decode(Double.self) {
      self = .number(n)
    } else {
      self = .preset(try container.decode(String.self))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .number(let value):
      try container.encode(value)
    case .preset(let value):
      try container.encode(value)
    }
  }
}

public enum LayoutHeight: Codable, Equatable, Sendable {
  case number(Double)
  case preset(String)

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let n = try? container.decode(Double.self) {
      self = .number(n)
    } else {
      self = .preset(try container.decode(String.self))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .number(let value):
      try container.encode(value)
    case .preset(let value):
      try container.encode(value)
    }
  }
}

public struct CommonStyle: Codable, Equatable, Sendable {
  public var padding: Padding? = nil
  public var margin: Padding? = nil
  public var radius: Double? = nil
  public var background: ThemedColor? = nil

  public var hasSurfaceChrome: Bool {
    if background != nil { return true }
    if (border?.width ?? 0) > 0 { return true }
    if (radius ?? 0) > 0 { return true }
    return false
  }
  public var border: Border? = nil
  public var shadow: DropShadow? = nil
  public var opacity: Double? = nil
  public var width: WidthValue? = nil
  public var position: String? = nil
  public var inset: Padding? = nil
  public var zIndex: Int? = nil
  /// Static rotation in degrees (CSS `rotate`); not timeline animation.
  public var rotate: Double? = nil
  public var height: LayoutHeight? = nil
  /// Stroke thickness in pt for layers that render a stroke primitive (e.g. loader ring).
  public var strokeWidth: Int? = nil
}

public struct TextStyle: Codable, Equatable, Sendable {
  public var padding: Padding? = nil
  public var margin: Padding? = nil
  public var radius: Double? = nil
  public var background: ThemedColor? = nil
  public var border: Border? = nil
  public var shadow: DropShadow? = nil
  public var opacity: Double? = nil
  public var width: WidthValue? = nil
  public var position: String? = nil
  public var inset: Padding? = nil
  public var zIndex: Int? = nil
  public var rotate: Double? = nil
  public var height: LayoutHeight? = nil
  public var fontFamily: String? = nil
  public var fontSize: Double? = nil
  public var fontWeight: Int? = nil
  public var color: ThemedColor? = nil
  public var align: String? = nil
  public var lineHeight: Double? = nil
  public var backgroundOpacity: Double? = nil
}

public struct ImageStyle: Codable, Equatable, Sendable {
  public var padding: Padding? = nil
  public var margin: Padding? = nil
  public var radius: Double? = nil
  public var background: ThemedColor? = nil
  public var border: Border? = nil
  public var shadow: DropShadow? = nil
  public var opacity: Double? = nil
  public var width: WidthValue? = nil
  public var position: String? = nil
  public var inset: Padding? = nil
  public var zIndex: Int? = nil
  public var rotate: Double? = nil
  public var height: LayoutHeight? = nil
  public var fit: String? = nil
  public var aspectRatio: Double? = nil
}

public struct IconStyle: Codable, Equatable, Sendable {
  public var padding: Padding? = nil
  public var margin: Padding? = nil
  public var radius: Double? = nil
  public var background: ThemedColor? = nil
  public var border: Border? = nil
  public var shadow: DropShadow? = nil
  public var opacity: Double? = nil
  public var width: WidthValue? = nil
  public var position: String? = nil
  public var inset: Padding? = nil
  public var zIndex: Int? = nil
  public var rotate: Double? = nil
  public var height: LayoutHeight? = nil
  public var color: ThemedColor? = nil
}

public struct ButtonStyle: Codable, Equatable, Sendable {
  public var padding: Padding? = nil
  public var margin: Padding? = nil
  public var radius: Double? = nil
  public var background: ThemedColor? = nil
  public var border: Border? = nil
  public var shadow: DropShadow? = nil
  public var opacity: Double? = nil
  public var width: WidthValue? = nil
  public var position: String? = nil
  public var inset: Padding? = nil
  public var zIndex: Int? = nil
  public var rotate: Double? = nil
  public var height: LayoutHeight? = nil
  public var fontSize: Double? = nil
  public var fontWeight: Int? = nil
  public var color: ThemedColor? = nil
  public var align: String? = nil
}

public typealias CommonStyleBreakpoints = [String: CommonStyle]
public typealias TextStyleBreakpoints = [String: TextStyle]
public typealias ImageStyleBreakpoints = [String: ImageStyle]
public typealias IconStyleBreakpoints = [String: IconStyle]
public typealias ButtonStyleBreakpoints = [String: ButtonStyle]

public struct StackLayoutPatch: Codable, Equatable, Sendable {
  public var gap: Double?
  public var direction: String?
}

public typealias StackLayoutBreakpoints = [String: StackLayoutPatch]
public typealias ButtonLayoutBreakpoints = [String: StackLayoutPatch]
