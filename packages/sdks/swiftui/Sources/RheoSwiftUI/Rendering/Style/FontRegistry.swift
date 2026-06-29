import Foundation

public enum RheoFontRegistry {
  public static func nativeFontFamilyName(styleId: String) -> String {
    "RheoFont__\(styleId)"
  }

  public static func buildFontLoadMap(branding: Branding?) -> [String: URL] {
    guard let branding else { return [:] }
    var out: [String: URL] = [:]
    for family in branding.fontFamilies {
      for style in family.styles {
        if let url = style.url {
          out[nativeFontFamilyName(styleId: style.id)] = url
        }
      }
    }
    return out
  }

  public static func resolveFontFamily(
    branding: Branding?,
    logicalName: String?,
    weight: Int?
  ) -> String? {
    guard let logicalName, !logicalName.isEmpty, logicalName != "system-ui" else { return nil }
    guard let family = branding?.fontFamilies.first(where: { $0.name == logicalName }) else {
      return logicalName
    }
    let desired = weight ?? 400
    let best = family.styles.min { abs($0.weight - desired) < abs($1.weight - desired) }
    guard let best else { return logicalName }
    return nativeFontFamilyName(styleId: best.id)
  }
}
