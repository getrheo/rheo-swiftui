import CoreText
import SwiftUI
import UIKit

public enum RheoIconFamily: String, Sendable {
  case ionicons
  case unknown
}

public struct RheoIconRenderer {
  public init() {}

  public func icon(family: String, name: String, size: CGFloat, color: Color) -> some View {
    let normalizedFamily = family.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    switch normalizedFamily {
    case "ionicons":
      return AnyView(ionicon(name: trimmedName, size: size, color: color))
    default:
      return AnyView(fallbackLabel(trimmedName, size: size, color: color))
    }
  }

  @ViewBuilder
  private func ionicon(name: String, size: CGFloat, color: Color) -> some View {
    if let glyph = IoniconsGlyphMap.unicode(for: name) {
      Text(String(glyph))
        .font(.custom(IoniconsGlyphMap.fontName, size: size))
        .foregroundStyle(color)
        .accessibilityHidden(true)
    } else {
      fallbackLabel(name, size: size, color: color)
    }
  }

  private func fallbackLabel(_ name: String, size: CGFloat, color: Color) -> some View {
    Text(name)
      .font(.system(size: min(11, size * 0.45)))
      .foregroundStyle(color.opacity(0.7))
      .lineLimit(3)
      .multilineTextAlignment(.center)
      .accessibilityLabel(name)
  }
}

enum IoniconsGlyphMap {
  static let fontName = "Ionicons"

  private static let map: [String: Int] = loadMap()

  static func unicode(for name: String) -> String? {
    let key = name.lowercased()
    guard let code = map[key], let scalar = UnicodeScalar(code) else { return nil }
    return String(Character(scalar))
  }

  private static func loadMap() -> [String: Int] {
    guard let url = Bundle.module.url(forResource: "ionicons-glyphmap", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return [:]
    }
    var map: [String: Int] = [:]
    for (key, value) in object {
      if let number = value as? NSNumber {
        map[key] = number.intValue
      } else if let intValue = value as? Int {
        map[key] = intValue
      }
    }
    return map
  }
}

public enum RheoIconFontRegistration {
  public static func registerBundledFonts() {
    guard let url = Bundle.module.url(forResource: "Ionicons", withExtension: "ttf", subdirectory: "Fonts") else {
      return
    }
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
  }
}
