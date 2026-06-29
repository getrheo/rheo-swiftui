import SwiftUI
import UIKit

/// `ScrollView` keeps an opaque `UIScrollView` background unless updated from UIKit / `containerBackground`.
struct RheoScrollCanvasModifier: ViewModifier {
  var uiColor: UIColor
  var mediaBackdrop: Bool

  func body(content: Content) -> some View {
    content
      .scrollContentBackground(.hidden)
      .background(mediaBackdrop ? Color.clear : Color(uiColor))
      .background(RheoScrollCanvasBackgroundFinder(uiColor: uiColor, mediaBackdrop: mediaBackdrop))
      .onAppear {
        UIScrollView.appearance().backgroundColor = mediaBackdrop ? .clear : uiColor
      }
      .onDisappear { UIScrollView.appearance().backgroundColor = nil }
  }
}

private struct RheoScrollCanvasBackgroundFinder: UIViewRepresentable {
  var uiColor: UIColor
  var mediaBackdrop: Bool

  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: .zero)
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    apply(to: uiView)
    for delay in [0.05, 0.15, 0.35] {
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        apply(to: uiView)
      }
    }
  }

  private func apply(to view: UIView) {
    let canvasColor = mediaBackdrop ? UIColor.clear : uiColor
    if let scroll = findScrollView(around: view) {
      scroll.backgroundColor = canvasColor
    }
    view.superview?.backgroundColor = canvasColor
  }

  private func findScrollView(around view: UIView) -> UIScrollView? {
    var ancestor: UIView? = view
    while let current = ancestor {
      if let scroll = current as? UIScrollView { return scroll }
      for sub in current.subviews {
        if let scroll = findScrollView(in: sub) { return scroll }
      }
      ancestor = current.superview
    }
    return nil
  }

  private func findScrollView(in view: UIView) -> UIScrollView? {
    if let scroll = view as? UIScrollView { return scroll }
    for sub in view.subviews {
      if let scroll = findScrollView(in: sub) { return scroll }
    }
    return nil
  }
}

extension View {
  func rheoScrollCanvas(mode: ThemeMode, mediaBackdrop: Bool = false) -> some View {
    modifier(
      RheoScrollCanvasModifier(
        uiColor: screenContainerFallbackUIColor(for: mode),
        mediaBackdrop: mediaBackdrop
      )
    )
  }
}

func screenCanvasColor(
  _ screen: Screen,
  theme: Theme?,
  branding: Branding?,
  mode: ThemeMode,
  width: Double
) -> Color {
  screenShellBackdropColor(screen, theme: theme, branding: branding, mode: mode, width: width)
    ?? screenContainerFallbackColor(for: mode)
}
