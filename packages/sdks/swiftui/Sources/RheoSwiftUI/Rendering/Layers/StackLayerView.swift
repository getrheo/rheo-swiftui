import SwiftUI

struct StackLayerView: View {
  var layer: StackLayer
  var ctx: LayerRendererContext
  @Environment(\.rheoLayoutWidth) private var rheoLayoutWidth
  @Environment(\.rheoParentStackDirection) private var rheoParentStackDirection

  var body: some View {
    let resolved = resolveCommonStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx)
    let selfIsAbsolute = resolved?.position == "absolute"
    let subtreeAbs = !selfIsAbsolute && layerSubtreeContainsAbsolutePosition(.stack(layer))
    // R5: the body region root fills its region (matches Web/RN `flex: 1`),
    // not merely a min-height equal to the region height.
    let rootBodyFill = ctx.isRegionRoot && ctx.regionKind == .body
    let rootBodyMinHeight = rootBodyFill ? ctx.regionHeight : nil
    let rootBodyMaxHeight: CGFloat? = rootBodyFill ? .infinity : nil
    let flowWidth = selfIsAbsolute ? nil : CGFloat.infinity
    let containerWidth = rheoLayoutWidth ?? CGFloat(ctx.previewWidthPx)
    let containerStyle = subtreeAbs ? styleWithoutPadding(resolved) : resolved
    let stackWidth = widthPoints(resolved?.width, containerWidth: containerWidth) ?? containerWidth

    Group {
      if subtreeAbs {
        // RN/Yoga positions absolute children from the parent's padding box, while flow children
        // start inside padding. Keep padding off the positioning container and apply it to flow only.
        ZStack(alignment: .topLeading) {
          flowStack
            .rheoStackPadding(resolved?.padding)
            .frame(width: stackWidth, alignment: .topLeading)
          ForEach(absoluteChildren, id: \.id) { child in
            renderChild(child, ctx: ctx)
          }
        }
        .frame(width: stackWidth, alignment: .topLeading)
        .frame(minHeight: rootBodyMinHeight, maxHeight: rootBodyMaxHeight, alignment: .topLeading)
      } else {
        flowStack
      }
    }
    .frame(
      maxWidth: flowWidth,
      minHeight: subtreeAbs ? nil : rootBodyMinHeight,
      maxHeight: subtreeAbs ? nil : rootBodyMaxHeight,
      alignment: .topLeading
    )
    .rheoCommonStyle(
      containerStyle,
      ctx: ctx,
      containerWidth: containerWidth
    )
    // R4 (Option A): a stack nested in a parent stack fills the parent main axis
    // unconditionally — independent of authored height — matching Web/RN `flex: 1`.
    .modifier(StackNestedMainAxisFill(parentDirection: selfIsAbsolute ? nil : rheoParentStackDirection))
  }

  private var absoluteChildren: [Layer] {
    layer.children
      .filter { layerHasAbsolutePositionAuthored($0) }
      .sorted { zIndexOrder($0) < zIndexOrder($1) }
  }

  private func zIndexOrder(_ layer: Layer) -> Int {
    resolvedCommonStyleForLayer(layer, previewWidthPx: ctx.previewWidthPx)?.zIndex ?? 0
  }

  @ViewBuilder private var flowStack: some View {
    if layer.direction == "horizontal" {
      HStack(alignment: verticalAlignment(layer.align), spacing: CGFloat(layer.gap ?? LayoutScalarDefaults.stackGap)) {
        flowChildren
      }
      .environment(\.rheoParentStackDirection, .horizontal)
    } else {
      VStack(alignment: horizontalAlignment(layer.align), spacing: CGFloat(layer.gap ?? LayoutScalarDefaults.stackGap)) {
        flowChildren
      }
      .environment(\.rheoParentStackDirection, .vertical)
    }
  }

  @ViewBuilder private var flowChildren: some View {
    ForEach(layer.children, id: \.id) { child in
      if !layerHasAbsolutePositionAuthored(child) {
        renderChild(child, ctx: ctx)
      }
    }
  }
}

private func styleWithoutPadding(_ style: CommonStyle?) -> CommonStyle? {
  guard var style else { return nil }
  style.padding = nil
  return style
}

/// Stack-specific main-axis fill for a stack nested inside a parent stack
/// (Option A). Unlike the generic `RheoFlowChildLayout` — which gates the
/// main-axis fill on authored `width: full` / `height: fill` — a nested stack
/// grows along the parent's main axis regardless of its authored size.
struct StackNestedMainAxisFill: ViewModifier {
  let parentDirection: RheoParentStackDirection?

  func body(content: Content) -> some View {
    switch parentDirection {
    case .some(.vertical):
      content.frame(maxHeight: .infinity, alignment: .topLeading)
    case .some(.horizontal):
      content.frame(maxWidth: .infinity, alignment: .topLeading)
    case .none:
      content
    }
  }
}

private extension View {
  func rheoStackPadding(_ insets: Padding?) -> some View {
    padding(.top, CGFloat(insets?.t ?? 0))
      .padding(.trailing, CGFloat(insets?.r ?? 0))
      .padding(.bottom, CGFloat(insets?.b ?? 0))
      .padding(.leading, CGFloat(insets?.l ?? 0))
  }
}
