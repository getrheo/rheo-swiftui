import SwiftUI

public struct ButtonPalette: Sendable {
  public var background: String
  public var color: String
  public var border: String
}

public func buttonPalette(_ variant: String, mode: ThemeMode) -> ButtonPalette {
  let dark = mode == .dark
  switch variant {
  case "primary":
    return dark
      ? ButtonPalette(background: "#fafafa", color: "#0a0a0a", border: "transparent")
      : ButtonPalette(background: "#0a0a0a", color: "#fafafa", border: "transparent")
  case "secondary":
    return dark
      ? ButtonPalette(background: "transparent", color: "#fafafa", border: "#27272a")
      : ButtonPalette(background: "transparent", color: "#0a0a0a", border: "#e4e4e7")
  case "ghost":
    return dark
      ? ButtonPalette(background: "transparent", color: "#fafafa", border: "transparent")
      : ButtonPalette(background: "transparent", color: "#0a0a0a", border: "transparent")
  case "destructive":
    return dark
      ? ButtonPalette(background: "#ef4444", color: "#fafafa", border: "transparent")
      : ButtonPalette(background: "#dc2626", color: "#fafafa", border: "transparent")
  default:
    return buttonPalette("secondary", mode: mode)
  }
}

public func widthPoints(_ width: WidthValue?, containerWidth: CGFloat) -> CGFloat? {
  guard let width else { return nil }
  switch width {
  case .number(let value): return CGFloat(value)
  case .preset(let preset):
    switch preset {
    case "full": return containerWidth
    case "1/2": return containerWidth * 0.5
    case "1/3": return containerWidth / 3
    case "2/3": return containerWidth * 2 / 3
    case "1/4": return containerWidth / 4
    case "3/4": return containerWidth * 3 / 4
    default: return nil
    }
  }
}

/// Maps `LayoutHeight` to SwiftUI points. Heights are `auto`, `full`/`fill`,
/// or fixed pt — no fractional values (those are widths only).
public func heightPoints(_ height: LayoutHeight?, containerHeight: CGFloat? = nil) -> CGFloat? {
  guard let height else { return nil }
  switch height {
  case .number(let value): return CGFloat(value)
  case .preset(let value):
    if value == "auto" { return nil }
    if value == "fill" || value == "full" { return containerHeight }
    return nil
  }
}

func rheoFontWeight(_ value: Int?) -> Font.Weight {
  guard let value else { return .regular }
  if value >= 800 { return .heavy }
  if value >= 700 { return .bold }
  if value >= 600 { return .semibold }
  if value >= 500 { return .medium }
  if value <= 300 { return .light }
  return .regular
}

func textAlignment(_ value: String?) -> TextAlignment {
  if value == "center" { return .center }
  if value == "right" { return .trailing }
  return .leading
}

func horizontalAlignment(_ value: String?) -> HorizontalAlignment {
  if value == "center" { return .center }
  if value == "end" { return .trailing }
  return .leading
}

func verticalAlignment(_ value: String?) -> VerticalAlignment {
  if value == "center" { return .center }
  if value == "end" { return .bottom }
  return .top
}

extension View {
  func rheoCommonStyle(
    _ style: CommonStyle?,
    ctx: LayerRendererContext,
    containerWidth: CGFloat
  ) -> some View {
    rheoCommonStyle(
      style,
      theme: ctx.manifest.theme,
      mode: ctx.theme,
      containerWidth: containerWidth,
      branding: ctx.branding
    )
  }

  func rheoCommonStyle(
    _ style: CommonStyle?,
    theme: Theme?,
    mode: ThemeMode,
    containerWidth: CGFloat,
    branding: Branding? = nil
  ) -> some View {
    let inner = stripCommonLayoutForInner(style)
    return self
      .rheoEdgeInsets(inner?.padding)
      .rheoSurfaceBox(inner, theme: theme, mode: mode, branding: branding)
      .rheoShadow(inner?.shadow, theme: theme, mode: mode)
      .opacity(inner?.opacity ?? 1)
      .frame(
        width: widthPoints(inner?.width, containerWidth: containerWidth),
        height: heightPoints(inner?.height)
      )
      .rheoEdgeInsets(inner?.margin)
      .rheoWrapperLayout(style, containerWidth: containerWidth)
  }

  @ViewBuilder
  func rheoWrapperLayout(_ style: CommonStyle?, containerWidth: CGFloat) -> some View {
    if let style, style.position == "absolute" {
      let boxWidth = widthPoints(style.width, containerWidth: containerWidth)
      let boxHeight = heightPoints(style.height)
      self
        .modifier(RheoZIndexModifier(zIndex: style.zIndex))
        .rheoAuthoredRotate(style.rotate)
        .fixedSize(horizontal: boxWidth == nil, vertical: boxHeight == nil)
        .frame(width: boxWidth, height: boxHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignmentFromInset(style.inset))
        .modifier(RheoAuthoredInsetPadding(inset: style.inset))
    } else if let style {
      self
        .modifier(RheoZIndexModifier(zIndex: style.zIndex))
        .rheoAuthoredRotate(style.rotate)
    } else {
      self
    }
  }

  @ViewBuilder
  func rheoAuthoredRotate(_ degrees: Double?) -> some View {
    if let degrees, degrees != 0 {
      rotationEffect(.degrees(degrees))
    } else {
      self
    }
  }

  private func rheoEdgeInsets(_ insets: Padding?) -> some View {
    padding(.top, CGFloat(insets?.t ?? 0))
      .padding(.trailing, CGFloat(insets?.r ?? 0))
      .padding(.bottom, CGFloat(insets?.b ?? 0))
      .padding(.leading, CGFloat(insets?.l ?? 0))
  }

  @ViewBuilder
  private func rheoSurfaceBox(_ style: CommonStyle?, theme: Theme?, mode: ThemeMode, branding: Branding?) -> some View {
    if let style {
      let fill = resolveSurfaceFill(style.background, theme: theme, branding: branding, mode: mode)
      let radius = CGFloat(style.radius ?? 0)
      let borderWidth = CGFloat(style.border?.width ?? 0)
      let hasBorder = borderWidth > 0
      let hasRadius = radius > 0
      if fill.hasAuthoredFill || hasBorder || hasRadius {
        let borderColor = resolveBorderColor(style.border?.color, theme: theme, mode: mode)
        let shape = RoundedRectangle(cornerRadius: radius)
        if fill.hasAuthoredFill {
          self
            .rheoSurfaceBackground(fill)
            .clipShape(shape)
            .overlay {
              if hasBorder {
                shape.stroke(borderColor, lineWidth: borderWidth)
              }
            }
        } else {
          self.clipShape(shape).overlay {
            if hasBorder {
              shape.stroke(borderColor, lineWidth: borderWidth)
            }
          }
        }
      } else {
        self
      }
    } else {
      self
    }
  }
}
