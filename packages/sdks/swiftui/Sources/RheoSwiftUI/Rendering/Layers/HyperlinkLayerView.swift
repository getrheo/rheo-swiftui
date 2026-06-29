import SwiftUI

struct HyperlinkLayerView: View {
  @Environment(\.openURL) private var openURL
  var layer: HyperlinkLayer
  var ctx: LayerRendererContext

  var body: some View {
    let resolved = resolveCommonStyleAtWidth(layer.style, layer.styleBreakpoints, width: ctx.previewWidthPx)
    Button {
      guard ctx.interactive, let url = URL(string: layer.href.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
      openURL(url) { accepted in
        if accepted {
          ctx.onHyperlinkOpened(layer.id, layer.href)
        }
      }
    } label: {
      Group {
        if layer.direction == "vertical" {
          VStack(alignment: horizontalAlignment(layer.align), spacing: CGFloat(layer.gap ?? LayoutScalarDefaults.hyperlinkGap)) {
            children
          }
        } else {
          HStack(alignment: verticalAlignment(layer.align), spacing: CGFloat(layer.gap ?? LayoutScalarDefaults.hyperlinkGap)) {
            children
          }
        }
      }
    }
    .buttonStyle(.plain)
    .disabled(!ctx.interactive)
    .rheoCommonStyle(resolved, ctx: ctx, containerWidth: CGFloat(ctx.previewWidthPx))
  }

  @ViewBuilder private var children: some View {
    ForEach(layer.children, id: \.id) { child in
      renderChild(child, ctx: ctx)
    }
  }
}
