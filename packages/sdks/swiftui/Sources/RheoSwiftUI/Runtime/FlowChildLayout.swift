import SwiftUI

/// Apply flex-item layout to the outer shell of a layer based on the
/// authored width/height and the parent stack direction. Mirrors the web
/// `flowChildLayoutCss` and React Native `flowChildLayoutViewStyle`.
///
/// Behavior parity:
/// - `width: full` in a horizontal stack → `.frame(maxWidth: .infinity)` and
///   layoutPriority 0 (parity with RN `flex: 1; min-width: 0`).
/// - `width: full` in a vertical stack → `.frame(maxWidth: .infinity)` and
///   `alignSelf: stretch` semantics.
/// - `height: fill`/`full` in a vertical stack → `.frame(maxHeight: .infinity)`.
/// - Absolute layers and layers outside a stack do nothing here; the
///   regular `rheoCommonStyle` modifier sizes the box.
struct RheoFlowChildLayout: ViewModifier {
  @Environment(\.rheoParentStackDirection) private var parentDirection
  let resolved: CommonStyle?

  func body(content: Content) -> some View {
    if resolved?.position == "absolute" || parentDirection == nil {
      content
    } else {
      content
        .modifier(WidthLayout(direction: parentDirection!, width: resolved?.width))
        .modifier(HeightLayout(direction: parentDirection!, height: resolved?.height))
    }
  }
}

private struct WidthLayout: ViewModifier {
  let direction: RheoParentStackDirection
  let width: WidthValue?

  func body(content: Content) -> some View {
    switch width {
    case .some(.preset(let preset)) where preset == "full":
      content.frame(maxWidth: .infinity)
    default:
      content
    }
  }
}

private struct HeightLayout: ViewModifier {
  let direction: RheoParentStackDirection
  let height: LayoutHeight?

  func body(content: Content) -> some View {
    switch height {
    case .some(.preset(let preset)) where preset == "fill" || preset == "full":
      content.frame(maxHeight: .infinity)
    default:
      content
    }
  }
}

extension View {
  /// Applies flex-item shell behavior reading the parent stack direction
  /// from the environment.
  func rheoFlowChildLayout(_ resolved: CommonStyle?) -> some View {
    modifier(RheoFlowChildLayout(resolved: resolved))
  }
}
