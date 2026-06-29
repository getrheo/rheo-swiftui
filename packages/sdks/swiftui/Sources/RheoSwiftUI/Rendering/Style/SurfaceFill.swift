import SwiftUI

struct ResolvedSurfaceFill: Equatable {
  var solid: Color?
  var gradient: BrandGradient?

  var hasAuthoredFill: Bool {
    solid != nil || gradient != nil
  }
}

func resolveSurfaceFill(
  _ color: ThemedColor?,
  theme: Theme?,
  branding: Branding?,
  mode: ThemeMode
) -> ResolvedSurfaceFill {
  if let gradient = brandGradient(for: color, branding: branding, mode: mode) {
    let fallback = gradient.stops.first.map { Color.rheo($0.color) }
    return ResolvedSurfaceFill(solid: fallback, gradient: gradient)
  }
  guard let css = resolveThemedBackgroundString(color, theme: theme, mode: mode) else {
    return ResolvedSurfaceFill()
  }
  if let solid = solidColorFromLinearGradientCss(css) {
    return ResolvedSurfaceFill(solid: solid)
  }
  guard let solid = colorFromCssString(css) else {
    return ResolvedSurfaceFill()
  }
  return ResolvedSurfaceFill(solid: solid)
}

func resolveSurfaceBackground(
  _ color: ThemedColor?,
  theme: Theme?,
  mode: ThemeMode,
  branding: Branding? = nil
) -> Color? {
  resolveSurfaceFill(color, theme: theme, branding: branding, mode: mode).solid
}

func resolveScreenShellFill(
  _ screen: Screen,
  theme: Theme?,
  branding: Branding?,
  mode: ThemeMode,
  width: Double
) -> ResolvedSurfaceFill {
  if let fill = resolveScreenBackgroundFillAtWidth(screen, width: width), fill.kind == .color {
    return resolveSurfaceFill(fill.color, theme: theme, branding: branding, mode: mode)
  }
  let shell = resolveCommonStyleAtWidth(
    screen.containerStyle?.asCommonStyle,
    nil,
    width: width
  )
  return resolveSurfaceFill(shell?.background, theme: theme, branding: branding, mode: mode)
}

/// Screen shell backdrop when `containerStyle.backgroundFill` (color) is authored.
func screenShellBackdropColor(
  _ screen: Screen,
  theme: Theme?,
  branding: Branding?,
  mode: ThemeMode,
  width: Double
) -> Color? {
  let fill = resolveScreenShellFill(screen, theme: theme, branding: branding, mode: mode, width: width)
  if let gradient = fill.gradient, let first = gradient.stops.first?.color {
    return Color.rheo(first)
  }
  return fill.solid
}

@ViewBuilder
func screenShellBackdropLayer(
  _ screen: Screen,
  theme: Theme?,
  branding: Branding?,
  mode: ThemeMode,
  width: Double
) -> some View {
  let fill = resolveScreenShellFill(screen, theme: theme, branding: branding, mode: mode, width: width)
  if fill.hasAuthoredFill {
    screenShellBackdropView(fill)
  } else {
    screenContainerFallbackColor(for: mode)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// Matches RN `Flow` / `LayerRenderer` shell backdrop when shell bg is unset.
func screenShellBackdropResolvedColor(
  _ screen: Screen,
  theme: Theme?,
  branding: Branding?,
  mode: ThemeMode,
  width: Double
) -> Color {
  screenShellBackdropColor(screen, theme: theme, branding: branding, mode: mode, width: width)
    ?? screenContainerFallbackColor(for: mode)
}

@ViewBuilder
func screenShellBackdropView(_ fill: ResolvedSurfaceFill) -> some View {
  if let gradient = fill.gradient {
    BrandGradientView(gradient: gradient)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  } else if let solid = fill.solid {
    solid
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

extension View {
  /// Applies `.background` only when the manifest authored a surface fill.
  @ViewBuilder
  func rheoSurfaceBackground(_ fill: ResolvedSurfaceFill, opacity: Double = 1) -> some View {
    if let gradient = fill.gradient {
      self.background {
        BrandGradientView(gradient: gradient)
      }
      .opacity(opacity)
    } else if let solid = fill.solid {
      self.background(solid.opacity(opacity))
    } else {
      self
    }
  }
}

/// Themed background string (tokens + pass-through); excludes brand-gradient tokens.
func resolveThemedBackgroundString(_ color: ThemedColor?, theme: Theme?, mode: ThemeMode) -> String? {
  guard let raw = resolveThemedColorString(color, theme: theme, mode: mode) else { return nil }
  if raw.hasPrefix(brandGradientPrefix) { return nil }
  return raw
}

func colorFromCssString(_ value: String) -> Color? {
  let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
  if trimmed.isEmpty || trimmed.lowercased() == "transparent" { return nil }
  if trimmed.hasPrefix("#") {
    return Color.rheo(trimmed)
  }
  if trimmed.lowercased().hasPrefix("rgb") {
    return parseRgbCssColor(trimmed)
  }
  if trimmed.lowercased().hasPrefix("hsl") {
    return parseHslCssColor(trimmed)
  }
  return nil
}

private func solidColorFromLinearGradientCss(_ css: String) -> Color? {
  guard css.lowercased().contains("gradient") else { return nil }
  guard let range = css.range(of: #"#[0-9a-fA-F]{3,8}"#, options: .regularExpression) else { return nil }
  return Color.rheo(String(css[range]))
}

private func parseRgbCssColor(_ value: String) -> Color? {
  let pattern = #"rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)"#
  guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
        let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
        match.numberOfRanges >= 4
  else { return nil }
  func component(_ index: Int) -> Double? {
    guard let range = Range(match.range(at: index), in: value) else { return nil }
    return Double(value[range])
  }
  guard let r = component(1), let g = component(2), let b = component(3) else { return nil }
  let a = match.numberOfRanges > 4 ? (component(4) ?? 1) : 1
  return Color(red: r / 255, green: g / 255, blue: b / 255, opacity: a)
}

private func parseHslCssColor(_ value: String) -> Color? {
  let pattern = #"hsla?\(\s*([\d.]+)\s*,\s*([\d.]+)%\s*,\s*([\d.]+)%\s*(?:,\s*([\d.]+)\s*)?\)"#
  guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
        let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
        match.numberOfRanges >= 4
  else { return nil }
  func component(_ index: Int) -> Double? {
    guard let range = Range(match.range(at: index), in: value) else { return nil }
    return Double(value[range])
  }
  guard let h = component(1), let s = component(2), let l = component(3) else { return nil }
  let a = match.numberOfRanges > 4 ? (component(4) ?? 1) : 1
  let (r, g, b) = hslToRgb(h: h / 360, s: s / 100, l: l / 100)
  return Color(red: r, green: g, blue: b, opacity: a)
}

private func hslToRgb(h: Double, s: Double, l: Double) -> (Double, Double, Double) {
  guard s > 0 else { return (l, l, l) }
  let q = l < 0.5 ? l * (1 + s) : l + s - l * s
  let p = 2 * l - q
  func hue(_ t: Double) -> Double {
    var x = t
    if x < 0 { x += 1 }
    if x > 1 { x -= 1 }
    if x < 1 / 6 { return p + (q - p) * 6 * x }
    if x < 1 / 2 { return q }
    if x < 2 / 3 { return p + (q - p) * (2 / 3 - x) * 6 }
    return p
  }
  return (hue(h + 1 / 3), hue(h), hue(h - 1 / 3))
}
