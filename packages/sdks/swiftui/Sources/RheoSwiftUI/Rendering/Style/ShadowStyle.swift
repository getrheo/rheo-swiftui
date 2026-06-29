import SwiftUI

func dropShadowHasAnyField(_ shadow: DropShadow?) -> Bool {
  guard let shadow else { return false }
  return shadow.offsetX != nil
    || shadow.offsetY != nil
    || shadow.blur != nil
    || shadow.spread != nil
    || shadow.color != nil
    || shadow.opacity != nil
}

/// Matches `@getrheo/flow-runtime` `dropShadowToNativeStyle` defaults (spread is web-only).
func resolveDropShadowColor(
  _ shadow: DropShadow?,
  theme: Theme?,
  mode: ThemeMode
) -> Color {
  let opacity = min(1, max(0, shadow?.opacity ?? 0.25))
  let base = resolveThemedColorString(shadow?.color, theme: theme, mode: mode) ?? "#000000"
  if let parsed = colorFromCssString(base) {
    return parsed.opacity(opacity)
  }
  return Color.rheo(base).opacity(opacity)
}

extension View {
  @ViewBuilder
  func rheoShadow(_ shadow: DropShadow?, theme: Theme?, mode: ThemeMode) -> some View {
    if dropShadowHasAnyField(shadow) {
      let offsetX = shadow?.offsetX ?? 0
      let offsetY = shadow?.offsetY ?? 2
      let blur = shadow?.blur ?? 8
      self.shadow(
        color: resolveDropShadowColor(shadow, theme: theme, mode: mode),
        radius: CGFloat(blur),
        x: CGFloat(offsetX),
        y: CGFloat(offsetY)
      )
    } else {
      self
    }
  }
}
