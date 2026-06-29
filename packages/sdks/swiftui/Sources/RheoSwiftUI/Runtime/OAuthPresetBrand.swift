import SwiftUI

public enum OAuthLoginPreset: String, Sendable {
  case github
  case google
  case apple
}

public struct OAuthPresetBrandModel: Equatable, Sendable {
  public var backgroundColor: String
  public var labelColor: String
  public var iconColor: String
  public var borderColor: String
  public var borderWidth: CGFloat
  public var fontSize: CGFloat
  public var fontWeight: Font.Weight
}

public func oauthPresetBrandModel(_ preset: OAuthLoginPreset, mode: ThemeMode) -> OAuthPresetBrandModel {
  switch preset {
  case .google:
    let fill = "#4285F4"
    if mode == .dark {
      return OAuthPresetBrandModel(
        backgroundColor: "#ffffff",
        labelColor: fill,
        iconColor: fill,
        borderColor: "#d1d5db",
        borderWidth: 1,
        fontSize: 14,
        fontWeight: .semibold
      )
    }
    return OAuthPresetBrandModel(
      backgroundColor: fill,
      labelColor: "#ffffff",
      iconColor: "#ffffff",
      borderColor: fill,
      borderWidth: 1,
      fontSize: 14,
      fontWeight: .semibold
    )
  case .apple:
    if mode == .dark {
      return OAuthPresetBrandModel(
        backgroundColor: "#ffffff",
        labelColor: "#000000",
        iconColor: "#000000",
        borderColor: "#d1d5db",
        borderWidth: 1,
        fontSize: 16,
        fontWeight: .semibold
      )
    }
    return OAuthPresetBrandModel(
      backgroundColor: "#000000",
      labelColor: "#ffffff",
      iconColor: "#ffffff",
      borderColor: "#000000",
      borderWidth: 1,
      fontSize: 16,
      fontWeight: .semibold
    )
  case .github:
    return OAuthPresetBrandModel(
      backgroundColor: "#24292f",
      labelColor: "#ffffff",
      iconColor: "#ffffff",
      borderColor: "#24292f",
      borderWidth: 1,
      fontSize: 14,
      fontWeight: .semibold
    )
  }
}

public func oauthPresetEffectiveLabel(
  provider: OAuthLoginPreset,
  label: LocalizedText?,
  locale: String
) -> String {
  let base: String
  switch provider {
  case .google: base = "Sign in with Google"
  case .github: base = "Continue with GitHub"
  case .apple: base = "Sign in with Apple"
  }
  guard let label else { return base }
  let resolved = label.resolve(locale: locale).trimmingCharacters(in: .whitespacesAndNewlines)
  return resolved.isEmpty ? base : resolved
}

public func oauthLoginPreset(from provider: String?) -> OAuthLoginPreset? {
  guard let provider else { return nil }
  return OAuthLoginPreset(rawValue: provider)
}
