import SwiftUI

private let choiceOptionSelectedIconSuffix = "_sel"
private let choiceOptionUnselectedIconSuffix = "_unsel"

/// Merges resolved default stack style with `selectedStyle` when the option is selected (matches web/RN).
func stackWithSelectedStyle(_ stack: StackLayer, isSelected: Bool, widthPx: Double) -> StackLayer {
  guard isSelected, let selectedStyle = stack.selectedStyle else { return stack }
  let resolved = resolveCommonStyleAtWidth(stack.style, stack.styleBreakpoints, width: widthPx)
  var out = stack
  out.style = mergeCommonStyle(resolved, selectedStyle)
  out.styleBreakpoints = nil
  return out
}

private func iconVisibilityForChoiceOption(_ layer: IconLayer, isSelected: Bool) -> IconLayer {
  var out = layer
  var style = layer.style ?? IconStyle()
  let baseOpacity = style.opacity ?? 1
  if layer.id.hasSuffix(choiceOptionSelectedIconSuffix) {
    style.opacity = isSelected ? baseOpacity : 0
    out.style = style
    return out
  }
  if layer.id.hasSuffix(choiceOptionUnselectedIconSuffix) {
    style.opacity = isSelected ? 0 : baseOpacity
    out.style = style
    return out
  }
  return layer
}

private func mapChoiceOptionChildForSelection(
  _ child: Layer,
  isSelected: Bool,
  widthPx: Double
) -> Layer {
  switch child {
  case .stack(var stack):
    let nestedSelected = isSelected && stack.selectedStyle != nil
    stack = stackWithSelectedStyle(stack, isSelected: nestedSelected, widthPx: widthPx)
    stack.children = stack.children.map { mapChoiceOptionChildForSelection($0, isSelected: isSelected, widthPx: widthPx) }
    return .stack(stack)
  case .icon(let icon):
    return .icon(iconVisibilityForChoiceOption(icon, isSelected: isSelected))
  default:
    return child
  }
}

/// Applies root + nested `selectedStyle` and toggles `_sel` / `_unsel` indicator icons.
func applyChoiceOptionSelectionToStack(_ stack: StackLayer, isSelected: Bool, widthPx: Double) -> StackLayer {
  var styled = stackWithSelectedStyle(stack, isSelected: isSelected, widthPx: widthPx)
  styled.children = styled.children.map { mapChoiceOptionChildForSelection($0, isSelected: isSelected, widthPx: widthPx) }
  return styled
}

func choiceOptionHasAuthoredLook(_ stack: StackLayer) -> Bool {
  stack.style?.background != nil
    || stack.style?.border != nil
    || stack.style?.padding != nil
    || stack.selectedStyle != nil
}

extension View {
  @ViewBuilder
  func rheoChoiceOptionPressDefaults(ctx: LayerRendererContext) -> some View {
    let palette = buttonPalette("secondary", mode: ctx.theme)
    padding(.vertical, 12)
      .padding(.horizontal, 14)
      .background(Color.rheo(palette.background))
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(Color.rheo(palette.border), lineWidth: palette.border == "transparent" ? 0 : 1)
      )
  }
}

@ViewBuilder
func choiceOptionLabel(
  stack: StackLayer,
  isSelected: Bool,
  ctx: LayerRendererContext
) -> some View {
  let styled = applyChoiceOptionSelectionToStack(stack, isSelected: isSelected, widthPx: ctx.previewWidthPx)
  let content = renderChild(.stack(styled), ctx: ctx)
  if choiceOptionHasAuthoredLook(stack) {
    content
  } else {
    content.rheoChoiceOptionPressDefaults(ctx: ctx)
  }
}
