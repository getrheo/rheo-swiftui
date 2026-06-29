import RheoSwiftUILottie
import SwiftUI

public protocol LottieRenderer: Sendable {
  associatedtype Body: View
  @ViewBuilder func lottie(url: URL, loop: Bool, contentMode: UIView.ContentMode) -> Body
}

public struct BundledLottieRenderer: LottieRenderer {
  public init() {}

  public func lottie(url: URL, loop: Bool, contentMode: UIView.ContentMode) -> some View {
    BundledLottieView(url: url, loop: loop, contentMode: contentMode)
  }
}

public struct PlaceholderLottieRenderer: LottieRenderer {
  public init() {}

  public func lottie(url: URL, loop: Bool, contentMode: UIView.ContentMode) -> some View {
    VStack(spacing: 6) {
      Image(systemName: "sparkles")
      Text("Lottie")
        .font(.caption2)
    }
    .foregroundStyle(.secondary)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityLabel("Lottie animation placeholder")
  }
}
