import SwiftUI

private struct CarouselWidthPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

private func carouselSlideWidth(containerWidth: CGFloat, peek: Double) -> CGFloat {
  max(0, containerWidth - CGFloat(peek) * 2)
}

private func carouselSlideIndex(layer: CarouselLayer) -> Int {
  let count = layer.slides.count
  guard count > 0 else { return 0 }
  return max(0, min(layer.openOn ?? 0, count - 1))
}

private func carouselVerticalAlignment(_ pageAlignment: String?) -> VerticalAlignment {
  if pageAlignment == "top" { return .top }
  if pageAlignment == "bottom" { return .bottom }
  return .center
}

private func carouselShouldEmitComplete(previousIndex: Int, index: Int, slideCount: Int, loop: Bool) -> Bool {
  if loop || slideCount <= 1 { return false }
  let last = slideCount - 1
  return index == last && previousIndex < last
}

private func carouselScrollTo(proxy: ScrollViewProxy, index: Int, slideCount: Int) {
  guard index >= 0, index < slideCount else { return }
  DispatchQueue.main.async {
    withAnimation(.easeOut(duration: 0.25)) {
      proxy.scrollTo(index, anchor: .center)
    }
  }
}

struct CarouselLayerView: View {
  var layer: CarouselLayer
  var ctx: LayerRendererContext
  @State private var index: Int
  @State private var previousIndex: Int
  @State private var containerWidth: CGFloat = 0
  @State private var didInitialScroll = false

  init(layer: CarouselLayer, ctx: LayerRendererContext) {
    self.layer = layer
    self.ctx = ctx
    let initial = carouselSlideIndex(layer: layer)
    _index = State(initialValue: initial)
    _previousIndex = State(initialValue: initial)
  }

  var body: some View {
    let resolved = resolveCommonStyleAtWidth(layer.style, nil, width: ctx.previewWidthPx)
    let inner = stripCommonLayoutForInner(resolved)
    let container = CGFloat(ctx.previewWidthPx)
    let authoredHeight = heightPoints(resolved?.height)
    let peek = CGFloat(layer.pagePeek ?? 0)
    let spacing = CGFloat(layer.pageSpacing ?? 0)
    let measureWidth = containerWidth > 0 ? containerWidth : container
    let slideWidth = carouselSlideWidth(containerWidth: measureWidth, peek: layer.pagePeek ?? 0)
    let loop = layer.loop == true

    VStack(spacing: 8) {
      if layer.pageControl?.position == "top" {
        dots
      }
      carouselScroll(peek: peek, spacing: spacing, slideWidth: slideWidth)
      if layer.pageControl?.position != "top" {
        dots
      }
    }
    .fixedSize(horizontal: false, vertical: authoredHeight == nil)
    .background(
      GeometryReader { geo in
        Color.clear.preference(key: CarouselWidthPreferenceKey.self, value: geo.size.width)
      }
    )
    .onPreferenceChange(CarouselWidthPreferenceKey.self) { containerWidth = $0 }
    .rheoCommonStyle(inner, ctx: ctx, containerWidth: container)
    .onChange(of: layer.openOn) { _ in
      let next = carouselSlideIndex(layer: layer)
      previousIndex = index
      index = next
      didInitialScroll = false
    }
    .onChange(of: index) { next in
      if ctx.interactive,
         carouselShouldEmitComplete(previousIndex: previousIndex, index: next, slideCount: layer.slides.count, loop: loop) {
        ctx.onRespond(.carousel)
      }
      previousIndex = next
    }
    .onAppear {
      if layer.autoAdvance == true {
        scheduleAutoAdvance()
      }
    }
  }

  @ViewBuilder
  private func carouselScroll(peek: CGFloat, spacing: CGFloat, slideWidth: CGFloat) -> some View {
    if #available(iOS 17.0, *) {
      ScrollView(.horizontal, showsIndicators: false) {
        carouselSlideRow(peek: peek, spacing: spacing, slideWidth: slideWidth)
      }
      .scrollPosition(id: scrollPositionBinding, anchor: .center)
    } else {
      ScrollViewReader { proxy in
        ScrollView(.horizontal, showsIndicators: false) {
          carouselSlideRow(peek: peek, spacing: spacing, slideWidth: slideWidth)
        }
        .onAppear {
          syncScrollPosition(proxy: proxy)
        }
        .onChange(of: containerWidth) { _ in
          syncScrollPosition(proxy: proxy)
        }
        .onChange(of: index) { next in
          carouselScrollTo(proxy: proxy, index: next, slideCount: layer.slides.count)
        }
      }
    }
  }

  @ViewBuilder
  private func carouselSlideRow(peek: CGFloat, spacing: CGFloat, slideWidth: CGFloat) -> some View {
    HStack(alignment: carouselVerticalAlignment(layer.pageAlignment), spacing: spacing) {
      ForEach(Array(layer.slides.enumerated()), id: \.element.id) { i, slide in
        renderChild(.stack(slide), ctx: ctx)
          .frame(width: slideWidth > 0 ? slideWidth : nil)
          .id(i)
      }
    }
    .padding(.horizontal, peek)
    .carouselScrollSnap(peek: peek, spacing: spacing)
  }

  @available(iOS 17.0, *)
  private var scrollPositionBinding: Binding<Int?> {
    Binding(
      get: { index },
      set: { next in
        guard let next, next >= 0, next < layer.slides.count else { return }
        previousIndex = index
        index = next
      }
    )
  }

  private func syncScrollPosition(proxy: ScrollViewProxy) {
    guard !didInitialScroll, containerWidth > 0, layer.slides.count > 0 else { return }
    didInitialScroll = true
    carouselScrollTo(proxy: proxy, index: index, slideCount: layer.slides.count)
  }

  private var dots: some View {
    HStack(spacing: CGFloat(layer.pageControl?.spacing ?? 6)) {
      ForEach(0..<layer.slides.count, id: \.self) { i in
        Capsule()
          .fill(i == index ? Color.accentColor : Color.secondary.opacity(0.35))
          .frame(width: i == index ? 18 : 6, height: 6)
      }
    }
  }

  private func scheduleAutoAdvance() {
    let delay = Double(layer.autoAdvanceMs ?? 4_000) / 1_000
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      let loop = layer.loop == true
      let slideCount = layer.slides.count
      let next: Int
      if index + 1 < slideCount {
        next = index + 1
      } else if loop {
        next = 0
      } else {
        next = index
      }
      previousIndex = index
      index = next
      scheduleAutoAdvance()
    }
  }
}

private extension View {
  @ViewBuilder
  func carouselScrollSnap(peek: CGFloat, spacing: CGFloat) -> some View {
    if #available(iOS 17.0, *) {
      self
        .scrollTargetBehavior(.viewAligned)
        .scrollTargetLayout()
    } else {
      self
    }
  }
}
