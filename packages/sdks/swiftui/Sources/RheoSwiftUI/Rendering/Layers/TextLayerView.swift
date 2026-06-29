import SwiftUI

struct TextLayerView: View {
  var layer: TextLayer
  var ctx: LayerRendererContext

  var body: some View {
    let resolved = resolveTextStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx)
    let isAbsolute = resolved?.position == "absolute"
    let copy = ctx.interpolationContext.map {
      resolveAndInterpolateLocalizedText(
        layer.text,
        manifest: ctx.manifest,
        locale: ctx.locale,
        responses: $0.responses,
        customProperties: $0.customProperties
      )
    } ?? layer.text.resolve(locale: ctx.locale)
    let textFill = resolveSurfaceFill(resolved?.background, theme: ctx.manifest.theme, branding: ctx.branding, mode: ctx.theme)
    let chromeStyle = resolved.map(\.commonStyleWithoutBackground)
    Text(copy)
      .font(textFont(resolved))
      .foregroundStyle(resolveColor(resolved?.color, theme: ctx.manifest.theme, mode: ctx.theme, fallback: defaultThemedForeground))
      .multilineTextAlignment(textAlignment(resolved?.align))
      .lineSpacing(lineSpacing(resolved))
      .frame(
        maxWidth: isAbsolute ? nil : .infinity,
        alignment: alignment(resolved?.align)
      )
      .rheoSurfaceBackground(textFill, opacity: resolved?.backgroundOpacity ?? 1)
      .rheoCommonStyle(chromeStyle, ctx: ctx, containerWidth: CGFloat(ctx.previewWidthPx))
  }

  private func textFont(_ style: TextStyle?) -> Font {
    let size = CGFloat(style?.fontSize ?? 14)
    let weight = rheoFontWeight(style?.fontWeight)
    if let family = RheoFontRegistry.resolveFontFamily(branding: ctx.branding, logicalName: style?.fontFamily ?? ctx.manifest.theme?.fontFamily, weight: style?.fontWeight) {
      return .custom(family, size: size)
    }
    return .system(size: size, weight: weight)
  }

  private func lineSpacing(_ style: TextStyle?) -> CGFloat {
    guard let lineHeight = style?.lineHeight, let size = style?.fontSize else { return 0 }
    return max(0, CGFloat(lineHeight * size - size))
  }

  private func alignment(_ align: String?) -> Alignment {
    if align == "center" { return .center }
    if align == "right" { return .trailing }
    return .leading
  }
}

extension TextStyle {
  var asCommonStyle: CommonStyle {
    var style = CommonStyle()
    style.padding = padding
    style.margin = margin
    style.radius = radius
    style.background = background
    style.border = border
    style.shadow = shadow
    style.opacity = opacity
    style.width = width
    style.position = position
    style.inset = inset
    style.zIndex = zIndex
    style.height = height
    return style
  }

  var commonStyleWithoutBackground: CommonStyle {
    var style = asCommonStyle
    style.background = nil
    return style
  }
}
