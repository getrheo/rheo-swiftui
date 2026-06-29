import SwiftUI

func commonStyleHasAbsolutePosition(
  _ style: CommonStyle?,
  breakpoints: CommonStyleBreakpoints?
) -> Bool {
  if style?.position == "absolute" { return true }
  guard let breakpoints else { return false }
  return breakpoints.values.contains { $0.position == "absolute" }
}

func layerHasAbsolutePositionAuthored(_ layer: Layer) -> Bool {
  switch layer {
  case .stack(let layer):
    return commonStyleHasAbsolutePosition(layer.style, breakpoints: layer.styleBreakpoints)
      || layer.selectedStyle?.position == "absolute"
  case .text(let layer):
    return commonStyleHasAbsolutePosition(
      layer.style?.asCommonStyle,
      breakpoints: layer.styleBreakpoints?.mapValues(\.asCommonStyle)
    )
  case .counter(let layer):
    return commonStyleHasAbsolutePosition(
      layer.style?.asCommonStyle,
      breakpoints: layer.styleBreakpoints?.mapValues(\.asCommonStyle)
    )
  case .image(let layer):
    return commonStyleHasAbsolutePosition(
      layer.style?.asCommonStyle,
      breakpoints: layer.styleBreakpoints?.mapValues(\.asCommonStyle)
    )
  case .lottie(let layer):
    return commonStyleHasAbsolutePosition(
      layer.style?.asCommonStyle,
      breakpoints: layer.styleBreakpoints?.mapValues(\.asCommonStyle)
    )
  case .video(let layer):
    return commonStyleHasAbsolutePosition(
      layer.style?.asCommonStyle,
      breakpoints: layer.styleBreakpoints?.mapValues(\.asCommonStyle)
    )
  case .icon(let layer):
    return commonStyleHasAbsolutePosition(
      layer.style?.asCommonStyle,
      breakpoints: layer.styleBreakpoints?.mapValues(\.asCommonStyle)
    )
  case .button(let layer):
    return commonStyleHasAbsolutePosition(
      layer.style?.asCommonStyle,
      breakpoints: layer.styleBreakpoints?.mapValues(\.asCommonStyle)
    )
  case .backButton(let layer):
    return commonStyleHasAbsolutePosition(
      layer.style?.asCommonStyle,
      breakpoints: layer.styleBreakpoints?.mapValues(\.asCommonStyle)
    )
  case .hyperlink(let layer):
    return commonStyleHasAbsolutePosition(layer.style, breakpoints: layer.styleBreakpoints)
  case .progress(let layer):
    return commonStyleHasAbsolutePosition(layer.style, breakpoints: nil)
  case .loader(let layer):
    return commonStyleHasAbsolutePosition(layer.style, breakpoints: nil)
  case .textInput(let layer):
    return commonStyleHasAbsolutePosition(layer.style, breakpoints: nil)
  case .scaleInput(let layer):
    return commonStyleHasAbsolutePosition(layer.style, breakpoints: nil)
  case .carousel(let layer):
    return commonStyleHasAbsolutePosition(layer.style, breakpoints: nil)
  case .oauthLogin(let layer):
    return commonStyleHasAbsolutePosition(layer.style, breakpoints: layer.styleBreakpoints)
  case .emailPasswordAuth(let layer):
    return commonStyleHasAbsolutePosition(layer.style, breakpoints: layer.styleBreakpoints)
  case .oauthProvider(let layer):
    return commonStyleHasAbsolutePosition(
      layer.style?.asCommonStyle,
      breakpoints: layer.styleBreakpoints?.mapValues(\.asCommonStyle)
    )
  case .emailPasswordField(let layer):
    return commonStyleHasAbsolutePosition(layer.style, breakpoints: layer.styleBreakpoints)
  case .emailPasswordSubmit(let layer):
    return commonStyleHasAbsolutePosition(
      layer.style?.asCommonStyle,
      breakpoints: layer.styleBreakpoints?.mapValues(\.asCommonStyle)
    )
  case .checkbox, .singleChoice, .multipleChoice:
    return false
  }
}

func layerSubtreeContainsAbsolutePosition(_ layer: Layer) -> Bool {
  if layerHasAbsolutePositionAuthored(layer) { return true }
  switch layer {
  case .stack(let layer):
    return layer.children.contains { layerSubtreeContainsAbsolutePosition($0) }
  case .carousel(let layer):
    return layer.slides.contains { layerSubtreeContainsAbsolutePosition(.stack($0)) }
  case .button(let layer):
    return layer.children.contains { layerSubtreeContainsAbsolutePosition($0) }
  case .backButton(let layer):
    return layer.children.contains { layerSubtreeContainsAbsolutePosition($0) }
  case .hyperlink(let layer):
    return layer.children.contains { layerSubtreeContainsAbsolutePosition($0) }
  case .singleChoice(let layer):
    return layer.children.contains { layerSubtreeContainsAbsolutePosition($0) }
  case .multipleChoice(let layer):
    return layer.children.contains { layerSubtreeContainsAbsolutePosition($0) }
  case .textInput(let layer):
    return (layer.children ?? []).contains { layerSubtreeContainsAbsolutePosition($0) }
  case .scaleInput(let layer):
    return (layer.children ?? []).contains { layerSubtreeContainsAbsolutePosition($0) }
  case .oauthLogin(let layer):
    return layer.children.contains { layerSubtreeContainsAbsolutePosition(.oauthProvider($0)) }
  case .oauthProvider(let layer):
    return (layer.children ?? []).contains { layerSubtreeContainsAbsolutePosition($0) }
  case .emailPasswordAuth(let layer):
    return layer.children.contains { layerSubtreeContainsAbsolutePosition($0.asLayer) }
  case .emailPasswordField(let layer):
    return (layer.children ?? []).contains { layerSubtreeContainsAbsolutePosition($0) }
  case .emailPasswordSubmit(let layer):
    return layer.children.contains { layerSubtreeContainsAbsolutePosition($0) }
  default:
    return false
  }
}

func stripCommonLayoutForInner(_ style: CommonStyle?) -> CommonStyle? {
  guard var style else { return nil }
  let wasAbsolute = style.position == "absolute"
  style.position = nil
  style.inset = nil
  style.zIndex = nil
  style.rotate = nil
  if wasAbsolute {
    style.width = nil
    style.height = nil
  }
  return style.padding != nil
    || style.margin != nil
    || style.background != nil
    || style.radius != nil
    || style.border != nil
    || style.shadow != nil
    || style.opacity != nil
    || style.width != nil
    || style.height != nil
    ? style
    : nil
}

func resolvedCommonStyleForLayer(_ layer: Layer, previewWidthPx: Double) -> CommonStyle? {
  switch layer {
  case .stack(let layer):
    return resolveCommonStyleAtWidth(layer.style, layer.styleBreakpoints, width: previewWidthPx)
  case .text(let layer):
    return resolveTextStyleAtWidth(layer.style, layer.styleBreakpoints, width: previewWidthPx)?.asCommonStyle
  case .hyperlink(let layer):
    return resolveCommonStyleAtWidth(layer.style, layer.styleBreakpoints, width: previewWidthPx)
  case .button(let layer):
    return resolveButtonStyleAtWidth(layer.style, layer.styleBreakpoints, width: previewWidthPx)?.asCommonStyle
  case .backButton(let layer):
    return resolveButtonStyleAtWidth(layer.style, layer.styleBreakpoints, width: previewWidthPx)?.asCommonStyle
  case .image(let layer):
    return resolveImageStyleAtWidth(layer.style, layer.styleBreakpoints, width: previewWidthPx)?.asCommonStyle
  case .icon(let layer):
    return resolveIconStyleAtWidth(layer.style, layer.styleBreakpoints, width: previewWidthPx)?.asCommonStyle
  case .counter(let layer):
    return resolveTextStyleAtWidth(layer.style, layer.styleBreakpoints, width: previewWidthPx)?.asCommonStyle
  case .checkbox(let layer):
    return resolveCommonStyleAtWidth(layer.style, layer.styleBreakpoints, width: previewWidthPx)
  case .singleChoice(let layer):
    return resolveCommonStyleAtWidth(layer.style, layer.styleBreakpoints, width: previewWidthPx)
  case .multipleChoice(let layer):
    return resolveCommonStyleAtWidth(layer.style, layer.styleBreakpoints, width: previewWidthPx)
  default:
    return nil
  }
}

func alignmentFromInset(_ inset: Padding?) -> Alignment {
  guard let inset else { return .center }
  let vertical: VerticalAlignment = inset.b != nil && inset.t == nil ? .bottom : .top
  let horizontal: HorizontalAlignment = inset.r != nil && inset.l == nil ? .trailing : .leading
  return Alignment(horizontal: horizontal, vertical: vertical)
}

struct RheoZIndexModifier: ViewModifier {
  var zIndex: Int?

  func body(content: Content) -> some View {
    if let zIndex {
      content.zIndex(Double(zIndex))
    } else {
      content
    }
  }
}

struct RheoAuthoredInsetPadding: ViewModifier {
  var inset: Padding?

  @ViewBuilder
  func body(content: Content) -> some View {
    if let inset {
      content
        .modifier(EdgePaddingModifier(edges: .top, value: inset.t))
        .modifier(EdgePaddingModifier(edges: .trailing, value: inset.r))
        .modifier(EdgePaddingModifier(edges: .bottom, value: inset.b))
        .modifier(EdgePaddingModifier(edges: .leading, value: inset.l))
    } else {
      content
    }
  }
}

private struct EdgePaddingModifier: ViewModifier {
  var edges: Edge.Set
  var value: Double?

  @ViewBuilder
  func body(content: Content) -> some View {
    if let value {
      content.padding(edges, CGFloat(value))
    } else {
      content
    }
  }
}
