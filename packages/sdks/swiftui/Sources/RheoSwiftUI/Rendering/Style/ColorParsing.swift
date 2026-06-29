import SwiftUI

extension Color {
  static func rheo(_ hex: String?, fallback: Color = .clear) -> Color {
    guard let hex else { return fallback }
    let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed == "transparent" { return .clear }
    guard trimmed.hasPrefix("#") else { return fallback }
    let raw = String(trimmed.dropFirst())
    let expanded: String
    if raw.count == 3 {
      expanded = raw.map { "\($0)\($0)" }.joined()
    } else {
      expanded = raw
    }
    guard let value = UInt64(expanded, radix: 16) else { return fallback }
    switch expanded.count {
    case 6:
      return Color(
        red: Double((value >> 16) & 0xff) / 255,
        green: Double((value >> 8) & 0xff) / 255,
        blue: Double(value & 0xff) / 255
      )
    case 8:
      return Color(
        red: Double((value >> 24) & 0xff) / 255,
        green: Double((value >> 16) & 0xff) / 255,
        blue: Double((value >> 8) & 0xff) / 255,
        opacity: Double(value & 0xff) / 255
      )
    default:
      return fallback
    }
  }
}

func resolveThemedColorString(_ color: ThemedColor?, theme: Theme?, mode: ThemeMode) -> String? {
  guard let color else { return nil }
  let raw: String?
  switch color {
  case .raw(let value):
    raw = value
  case .modes(let light, let dark):
    raw = mode == .dark ? (dark ?? light) : (light ?? dark)
  }
  guard let raw else { return nil }
  return resolveThemeToken(raw, theme: theme, mode: mode)
}

private func resolveThemeToken(_ value: String, theme: Theme?, mode: ThemeMode) -> String? {
  guard value.hasPrefix("$") else { return value }
  let key = String(value.dropFirst())
  switch key {
  case "primary":
    return theme?.primary.flatMap { resolveThemedColorString($0, theme: theme, mode: mode) }
  case "primaryForeground":
    return theme?.primaryForeground.flatMap { resolveThemedColorString($0, theme: theme, mode: mode) }
  case "background":
    return theme?.background.flatMap { resolveThemedColorString($0, theme: theme, mode: mode) }
  case "foreground":
    return theme?.foreground.flatMap { resolveThemedColorString($0, theme: theme, mode: mode) }
  case "accent":
    return theme?.accent.flatMap { resolveThemedColorString($0, theme: theme, mode: mode) }
  default:
    return nil
  }
}

/// Foreground / stroke colors. Pass an explicit `fallback` when a default is desired.
func resolveColor(_ color: ThemedColor?, theme: Theme?, mode: ThemeMode, fallback: ThemedColor? = nil) -> Color {
  let resolved = resolveThemedColorString(color, theme: theme, mode: mode)
    ?? resolveThemedColorString(fallback, theme: theme, mode: mode)
  guard let resolved else { return .clear }
  return colorFromCssString(resolved) ?? .clear
}

func resolveBorderColor(_ color: ThemedColor?, theme: Theme?, mode: ThemeMode) -> Color {
  .rheo(resolveThemedColorString(color, theme: theme, mode: mode), fallback: .clear)
}

/// Default screen canvas when `containerStyle.backgroundFill` is unset (`#000000` dark, `#ffffff` light).
func screenContainerFallbackColor(for mode: ThemeMode) -> Color {
  mode == .dark ? .black : .white
}

func screenContainerFallbackUIColor(for mode: ThemeMode) -> UIColor {
  mode == .dark ? .black : .white
}

func effectiveThemeMode(explicit: ThemeMode?, colorScheme: ColorScheme) -> ThemeMode {
  explicit ?? (colorScheme == .light ? .light : .dark)
}

func resolveColorString(_ color: ThemedColor?, theme: Theme?, mode: ThemeMode, fallback: ThemedColor? = nil) -> String? {
  resolveThemedColorString(color, theme: theme, mode: mode)
    ?? resolveThemedColorString(fallback, theme: theme, mode: mode)
}
