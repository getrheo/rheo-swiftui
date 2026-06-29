import Foundation

public struct BrandColor: Codable, Equatable, Sendable {
  public var id: String
  public var name: String
  public var value: String
}

public struct BrandGradientStop: Codable, Equatable, Sendable {
  public var offset: Double
  public var color: String
}

public struct BrandGradient: Codable, Equatable, Sendable {
  public var id: String
  public var name: String
  public var type: String
  public var angle: Double?
  public var stops: [BrandGradientStop]
}

public struct FontStyle: Codable, Equatable, Sendable {
  public var id: String
  public var weight: Int
  public var italic: Bool
  public var label: String?
  public var mediaAssetId: String?
  public var url: URL?
  public var filename: String?
}

public struct FontFamily: Codable, Equatable, Sendable {
  public var id: String
  public var name: String
  public var styles: [FontStyle]
}

public struct AppIcon: Codable, Equatable, Sendable {
  public var url: URL
  public var source: String
}

public struct Branding: Codable, Equatable, Sendable {
  public var appIcon: AppIcon?
  public var colorPresets: [BrandColor]
  public var gradientPresets: [BrandGradient]
  public var fontFamilies: [FontFamily]
}
