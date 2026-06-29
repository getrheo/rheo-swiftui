import SwiftUI

struct SingleChoiceLayerView: View {
  @EnvironmentObject private var draft: ScreenInputDraftStore
  var layer: SingleChoiceLayer
  var ctx: LayerRendererContext

  var body: some View {
    choiceContainer {
      ForEach(layer.optionBindings, id: \.optionId) { binding in
        option(binding.optionId) {
          if screenHasContinueButton(ctx.screen) {
            draft.draft = .choice(binding.optionId)
          } else {
            ctx.onRespond(.choice(choiceId: binding.optionId))
          }
        }
      }
    }
    .rheoCommonStyle(
      resolveCommonStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx),
      ctx: ctx,
      containerWidth: CGFloat(ctx.previewWidthPx)
    )
  }

  @ViewBuilder private func option(_ optionId: String, action: @escaping () -> Void) -> some View {
    if let stack = findOptionStackForChoice(.singleChoice(layer), optionId: optionId) {
      let selected = isSelected(optionId)
      Button(action: action) {
        choiceOptionLabel(stack: stack, isSelected: selected, ctx: ctx)
      }
      .buttonStyle(.plain)
      .disabled(!ctx.interactive)
    }
  }

  private func isSelected(_ id: String) -> Bool {
    guard screenHasContinueButton(ctx.screen) else { return false }
    if case .choice(let selected)? = draft.draft { return selected == id }
    return false
  }

  @ViewBuilder private func choiceContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    if layer.direction == "horizontal" || layer.direction == "grid" {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: CGFloat(layer.gap ?? LayoutScalarDefaults.choiceGap)), count: max(1, layer.direction == "grid" ? (layer.columns ?? 2) : layer.optionBindings.count)), spacing: CGFloat(layer.gap ?? LayoutScalarDefaults.choiceGap)) {
        content()
      }
    } else {
      VStack(spacing: CGFloat(layer.gap ?? LayoutScalarDefaults.choiceGap)) {
        content()
      }
    }
  }
}

struct MultipleChoiceLayerView: View {
  @EnvironmentObject private var draft: ScreenInputDraftStore
  var layer: MultipleChoiceLayer
  var ctx: LayerRendererContext

  var selected: Set<String> {
    if case .multiChoice(let ids)? = draft.draft { return Set(ids) }
    return []
  }

  var body: some View {
    let columns = layer.direction == "grid" ? max(1, layer.columns ?? 2) : (layer.direction == "horizontal" ? layer.optionBindings.count : 1)
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: CGFloat(layer.gap ?? LayoutScalarDefaults.choiceGap)), count: max(1, columns)), spacing: CGFloat(layer.gap ?? LayoutScalarDefaults.choiceGap)) {
      ForEach(layer.optionBindings, id: \.optionId) { binding in
        if let stack = findOptionStackForChoice(.multipleChoice(layer), optionId: binding.optionId) {
          let isSelected = selected.contains(binding.optionId)
          Button {
            toggle(binding.optionId)
          } label: {
            choiceOptionLabel(stack: stack, isSelected: isSelected, ctx: ctx)
          }
          .buttonStyle(.plain)
          .disabled(!ctx.interactive)
        }
      }
    }
    .rheoCommonStyle(
      resolveCommonStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx),
      ctx: ctx,
      containerWidth: CGFloat(ctx.previewWidthPx)
    )
  }

  private func toggle(_ optionId: String) {
    var next = selected
    if next.contains(optionId) {
      next.remove(optionId)
    } else {
      if let max = layer.maxSelections, next.count >= max { return }
      next.insert(optionId)
    }
    draft.draft = next.isEmpty ? nil : .multiChoice(Array(next))
  }
}
