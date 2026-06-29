import SwiftUI

struct ButtonLayerView: View {
  @EnvironmentObject private var draft: ScreenInputDraftStore
  @EnvironmentObject private var checkbox: CheckboxAckStore
  @EnvironmentObject private var mediaPlayback: MediaPlaybackCoordinator
  var layer: ButtonLayer
  var ctx: LayerRendererContext

  var body: some View {
    let disabled = isDisabled
    Button {
      guard !disabled else { return }
      if case .requestAppReview = layer.action {
        let snap = checkbox.snapshotValues()
        let capturedDraft = draft.toResponse()?.eligibleConsumedDraft
        ctx.onAction(layer.action, layer.id, AppReviewButtonCommit(checkboxValues: snap, capturedDraft: capturedDraft))
        return
      }
      ctx.onAction(layer.action, layer.id, nil)
      switch layer.action {
      case .none:
        return
      case .playMedia(let targetLayerIds):
        mediaPlayback.playMedia(layerIds: targetLayerIds)
        return
      case .continue:
        let primary = draft.toResponse() ?? .cta(action: "primary")
        let snap = checkbox.snapshotValues()
        if snap.isEmpty {
          ctx.onRespond(primary)
        } else {
          ctx.onRespond(.screenCommit(primary: primary, checkboxValues: snap, capturedDraft: nil))
        }
      case .skip:
        ctx.onRespond(.skip(consumedDraft: nil))
      case .endFlow:
        ctx.onRespond(.endFlow(consumedDraft: draft.toResponse()?.eligibleConsumedDraft))
      case .goToStep(let screenId):
        ctx.onRespond(.goToScreen(screenId: screenId))
      case .goBackOneScreen(let fallbackScreenId):
        ctx.onRespond(.goBack(fallbackScreenId: fallbackScreenId))
      case .requestOSPermission, .requestAppReview:
        break
      }
    } label: {
      ButtonContent(children: layer.children, style: layer.style, variant: layer.variant, ctx: ctx)
    }
    .buttonStyle(.plain)
    .opacity(disabled && ctx.interactive ? 0.5 : 1)
    .disabled(disabled)
  }

  private var isDisabled: Bool {
    if case .none = layer.action { return true }
    let isContinue = layer.action == .continue
    let goBackDisabled: Bool
    if case .goBackOneScreen(let fallback) = layer.action {
      goBackDisabled = ctx.interpolationContext?.canGoBack != true && fallback == nil
    } else {
      goBackDisabled = false
    }
    return !ctx.interactive || (isContinue && !draft.validity) || (isContinue && checkbox.blockingContinue) || goBackDisabled
  }
}

struct BackButtonLayerView: View {
  var layer: BackButtonLayer
  var ctx: LayerRendererContext

  var body: some View {
    let disabled = !ctx.interactive || (ctx.interpolationContext?.canGoBack != true && layer.fallbackScreenId == nil)
    Button {
      ctx.onRespond(.goBack(fallbackScreenId: layer.fallbackScreenId))
    } label: {
      ButtonContent(children: layer.children, style: layer.style, variant: layer.variant, ctx: ctx)
    }
    .buttonStyle(.plain)
    .opacity(disabled && ctx.interactive ? 0.5 : 1)
    .disabled(disabled)
  }
}

private struct ButtonContent: View {
  var children: [Layer]
  var style: ButtonStyle?
  var variant: String
  var ctx: LayerRendererContext
  @Environment(\.rheoLayoutWidth) private var rheoLayoutWidth

  var body: some View {
    let palette = buttonPalette(variant, mode: ctx.theme)
    let containerWidth = rheoLayoutWidth ?? CGFloat(ctx.previewWidthPx)
    let common = style.map { $0.asCommonStyle }
    // No forced `.frame(maxWidth: .infinity)`. The button hugs its content
    // unless the author sets `style.width = full` (or a fixed value), in
    // which case `rheoCommonStyle` sizes the outer frame to match.
    HStack(spacing: 8) {
      ForEach(children, id: \.id) { child in
        if case .text(let textLayer) = child {
          ButtonLabelText(textLayer: textLayer, buttonStyle: style, palette: palette, ctx: ctx)
        } else {
          renderChild(child, ctx: ctx)
        }
      }
    }
    .padding(.vertical, CGFloat(style?.padding?.t ?? 12))
    .padding(.horizontal, CGFloat(style?.padding?.l ?? 16))
    .rheoButtonChromeBackground(style: style, palette: palette, ctx: ctx)
    .clipShape(RoundedRectangle(cornerRadius: CGFloat(style?.radius ?? 10)))
    .overlay(
      RoundedRectangle(cornerRadius: CGFloat(style?.radius ?? 10))
        .stroke(Color.rheo(palette.border), lineWidth: palette.border == "transparent" ? 0 : 1)
    )
    .rheoFlowChildLayout(common)
    .frame(
      width: widthPoints(common?.width, containerWidth: containerWidth),
      height: heightPoints(common?.height)
    )
    // R9: apply the button's own outer-shell layout (margin, then
    // position/inset/zIndex/rotate) so authored values on a button style take
    // effect, matching the stack/common-style path.
    .padding(.top, CGFloat(common?.margin?.t ?? 0))
    .padding(.trailing, CGFloat(common?.margin?.r ?? 0))
    .padding(.bottom, CGFloat(common?.margin?.b ?? 0))
    .padding(.leading, CGFloat(common?.margin?.l ?? 0))
    .rheoWrapperLayout(common, containerWidth: containerWidth)
  }
}

struct ButtonLabelText: View {
  var textLayer: TextLayer
  var buttonStyle: ButtonStyle?
  var palette: ButtonPalette
  var ctx: LayerRendererContext

  var body: some View {
    let textStyle = textLayer.style
    let size = CGFloat(textStyle?.fontSize ?? buttonStyle?.fontSize ?? 13)
    let weight = rheoFontWeight(textStyle?.fontWeight ?? buttonStyle?.fontWeight ?? 600)
    let copy = textLayer.text.resolve(locale: ctx.locale)
    let color = resolveColor(
      textStyle?.color ?? buttonStyle?.color,
      theme: ctx.manifest.theme,
      mode: ctx.theme,
      fallback: .raw(palette.color)
    )
    Text(copy)
      .font(.system(size: size, weight: weight))
      .foregroundStyle(color)
      .multilineTextAlignment(textAlignment(textStyle?.align ?? buttonStyle?.align))
  }
}

extension View {
  @ViewBuilder
  func rheoButtonChromeBackground(style: ButtonStyle?, palette: ButtonPalette, ctx: LayerRendererContext) -> some View {
    let authorFill = resolveSurfaceFill(
      style?.background,
      theme: ctx.manifest.theme,
      branding: ctx.branding,
      mode: ctx.theme
    )
    if authorFill.hasAuthoredFill {
      rheoSurfaceBackground(authorFill)
    } else {
      let variantFill = resolveSurfaceFill(
        .raw(palette.background),
        theme: ctx.manifest.theme,
        branding: ctx.branding,
        mode: ctx.theme
      )
      if variantFill.hasAuthoredFill {
        rheoSurfaceBackground(variantFill)
      } else {
        self
      }
    }
  }
}

extension ButtonStyle {
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
    style.rotate = rotate
    style.height = height
    return style
  }
}
