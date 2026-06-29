import Foundation

let defaultPreviewViewportWidthPx: Double = 390

private let breakpointMinWidth: [(String, Double)] = [
  ("sm", 640),
  ("md", 768),
  ("lg", 1024),
  ("xl", 1280),
  ("2xl", 1536),
]

public func activeBreakpointKeys(width: Double) -> [String] {
  breakpointMinWidth.filter { width >= $0.1 }.map(\.0)
}

public func resolveCommonStyleAtWidth(
  _ base: CommonStyle?,
  _ breakpoints: CommonStyleBreakpoints?,
  width: Double
) -> CommonStyle? {
  var out = base
  for key in activeBreakpointKeys(width: width) {
    if let patch = breakpoints?[key] {
      out = mergeCommonStyle(out, patch)
    }
  }
  return out
}

public func resolveTextStyleAtWidth(
  _ base: TextStyle?,
  _ breakpoints: TextStyleBreakpoints?,
  width: Double
) -> TextStyle? {
  var out = base
  for key in activeBreakpointKeys(width: width) {
    if let patch = breakpoints?[key] {
      out = mergeTextStyle(out, patch)
    }
  }
  return out
}

public func resolveImageStyleAtWidth(
  _ base: ImageStyle?,
  _ breakpoints: ImageStyleBreakpoints?,
  width: Double
) -> ImageStyle? {
  var out = base
  for key in activeBreakpointKeys(width: width) {
    if let patch = breakpoints?[key] {
      out = mergeImageStyle(out, patch)
    }
  }
  return out
}

public func resolveIconStyleAtWidth(
  _ base: IconStyle?,
  _ breakpoints: IconStyleBreakpoints?,
  width: Double
) -> IconStyle? {
  var out = base
  for key in activeBreakpointKeys(width: width) {
    if let patch = breakpoints?[key] {
      out = mergeIconStyle(out, patch)
    }
  }
  return out
}

public func resolveButtonStyleAtWidth(
  _ base: ButtonStyle?,
  _ breakpoints: ButtonStyleBreakpoints?,
  width: Double
) -> ButtonStyle? {
  var out = base
  for key in activeBreakpointKeys(width: width) {
    if let patch = breakpoints?[key] {
      out = mergeButtonStyle(out, patch)
    }
  }
  return out
}

func mergeCommonStyle(_ base: CommonStyle?, _ patch: CommonStyle) -> CommonStyle {
  var out = base ?? CommonStyle()
  if patch.padding != nil { out.padding = patch.padding }
  if patch.margin != nil { out.margin = patch.margin }
  if patch.radius != nil { out.radius = patch.radius }
  if patch.background != nil { out.background = patch.background }
  if patch.border != nil { out.border = patch.border }
  if patch.shadow != nil { out.shadow = patch.shadow }
  if patch.opacity != nil { out.opacity = patch.opacity }
  if patch.width != nil { out.width = patch.width }
  if patch.position != nil { out.position = patch.position }
  if patch.inset != nil { out.inset = patch.inset }
  if patch.zIndex != nil { out.zIndex = patch.zIndex }
  if patch.rotate != nil { out.rotate = patch.rotate }
  if patch.height != nil { out.height = patch.height }
  if patch.strokeWidth != nil { out.strokeWidth = patch.strokeWidth }
  return out
}

func mergeTextStyle(_ base: TextStyle?, _ patch: TextStyle) -> TextStyle {
  var out = base ?? TextStyle()
  if patch.padding != nil { out.padding = patch.padding }
  if patch.margin != nil { out.margin = patch.margin }
  if patch.radius != nil { out.radius = patch.radius }
  if patch.background != nil { out.background = patch.background }
  if patch.border != nil { out.border = patch.border }
  if patch.shadow != nil { out.shadow = patch.shadow }
  if patch.opacity != nil { out.opacity = patch.opacity }
  if patch.width != nil { out.width = patch.width }
  if patch.position != nil { out.position = patch.position }
  if patch.inset != nil { out.inset = patch.inset }
  if patch.zIndex != nil { out.zIndex = patch.zIndex }
  if patch.rotate != nil { out.rotate = patch.rotate }
  if patch.height != nil { out.height = patch.height }
  if patch.fontFamily != nil { out.fontFamily = patch.fontFamily }
  if patch.fontSize != nil { out.fontSize = patch.fontSize }
  if patch.fontWeight != nil { out.fontWeight = patch.fontWeight }
  if patch.color != nil { out.color = patch.color }
  if patch.align != nil { out.align = patch.align }
  if patch.lineHeight != nil { out.lineHeight = patch.lineHeight }
  if patch.backgroundOpacity != nil { out.backgroundOpacity = patch.backgroundOpacity }
  return out
}

func mergeImageStyle(_ base: ImageStyle?, _ patch: ImageStyle) -> ImageStyle {
  var out = base ?? ImageStyle()
  if patch.padding != nil { out.padding = patch.padding }
  if patch.margin != nil { out.margin = patch.margin }
  if patch.radius != nil { out.radius = patch.radius }
  if patch.background != nil { out.background = patch.background }
  if patch.border != nil { out.border = patch.border }
  if patch.shadow != nil { out.shadow = patch.shadow }
  if patch.opacity != nil { out.opacity = patch.opacity }
  if patch.width != nil { out.width = patch.width }
  if patch.position != nil { out.position = patch.position }
  if patch.inset != nil { out.inset = patch.inset }
  if patch.zIndex != nil { out.zIndex = patch.zIndex }
  if patch.rotate != nil { out.rotate = patch.rotate }
  if patch.height != nil { out.height = patch.height }
  if patch.fit != nil { out.fit = patch.fit }
  if patch.aspectRatio != nil { out.aspectRatio = patch.aspectRatio }
  return out
}

func mergeIconStyle(_ base: IconStyle?, _ patch: IconStyle) -> IconStyle {
  var out = base ?? IconStyle()
  if patch.padding != nil { out.padding = patch.padding }
  if patch.margin != nil { out.margin = patch.margin }
  if patch.radius != nil { out.radius = patch.radius }
  if patch.background != nil { out.background = patch.background }
  if patch.border != nil { out.border = patch.border }
  if patch.shadow != nil { out.shadow = patch.shadow }
  if patch.opacity != nil { out.opacity = patch.opacity }
  if patch.width != nil { out.width = patch.width }
  if patch.position != nil { out.position = patch.position }
  if patch.inset != nil { out.inset = patch.inset }
  if patch.zIndex != nil { out.zIndex = patch.zIndex }
  if patch.rotate != nil { out.rotate = patch.rotate }
  if patch.height != nil { out.height = patch.height }
  if patch.color != nil { out.color = patch.color }
  return out
}

func mergeButtonStyle(_ base: ButtonStyle?, _ patch: ButtonStyle) -> ButtonStyle {
  var out = base ?? ButtonStyle()
  if patch.padding != nil { out.padding = patch.padding }
  if patch.margin != nil { out.margin = patch.margin }
  if patch.radius != nil { out.radius = patch.radius }
  if patch.background != nil { out.background = patch.background }
  if patch.border != nil { out.border = patch.border }
  if patch.shadow != nil { out.shadow = patch.shadow }
  if patch.opacity != nil { out.opacity = patch.opacity }
  if patch.width != nil { out.width = patch.width }
  if patch.position != nil { out.position = patch.position }
  if patch.inset != nil { out.inset = patch.inset }
  if patch.zIndex != nil { out.zIndex = patch.zIndex }
  if patch.rotate != nil { out.rotate = patch.rotate }
  if patch.height != nil { out.height = patch.height }
  if patch.fontSize != nil { out.fontSize = patch.fontSize }
  if patch.fontWeight != nil { out.fontWeight = patch.fontWeight }
  if patch.color != nil { out.color = patch.color }
  if patch.align != nil { out.align = patch.align }
  return out
}
