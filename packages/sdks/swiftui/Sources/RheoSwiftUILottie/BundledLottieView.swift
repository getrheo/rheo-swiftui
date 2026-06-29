import Lottie
import SwiftUI

public struct BundledLottieView: UIViewRepresentable {
  public var url: URL
  public var loop: Bool
  public var contentMode: UIView.ContentMode

  public init(url: URL, loop: Bool, contentMode: UIView.ContentMode) {
    self.url = url
    self.loop = loop
    self.contentMode = contentMode
  }

  public func makeUIView(context: Context) -> LottieAnimationView {
    let view = LottieAnimationView()
    view.backgroundBehavior = .pauseAndRestore
    configure(view)
    return view
  }

  public func updateUIView(_ uiView: LottieAnimationView, context: Context) {
    configure(uiView)
  }

  private func configure(_ view: LottieAnimationView) {
    view.contentMode = contentMode
    view.loopMode = loop ? .loop : .playOnce
    LottieAnimation.loadedFrom(url: url) { animation in
      guard let animation else { return }
      view.animation = animation
      view.play()
    }
  }
}
