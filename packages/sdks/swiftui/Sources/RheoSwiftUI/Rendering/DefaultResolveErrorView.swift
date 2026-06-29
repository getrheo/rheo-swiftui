import SwiftUI

public enum DefaultResolveErrorCopy {
  public static let title = "Error to load the content"
  public static let retryLabel = "Try again"
  public static let hint = "Check your connection and try again."
}

public struct DefaultResolveErrorView: View {
  public var theme: ThemeMode
  public var onRetry: () -> Void

  public init(theme: ThemeMode, onRetry: @escaping () -> Void) {
    self.theme = theme
    self.onRetry = onRetry
  }

  public var body: some View {
    let fg = theme == .dark ? Color.white : Color.black
    let muted = theme == .dark ? Color(white: 0.63) : Color(white: 0.45)
    let buttonBg = theme == .dark ? Color.white : Color.black
    let buttonFg = theme == .dark ? Color.black : Color.white

    VStack(spacing: 20) {
      Text(DefaultResolveErrorCopy.title)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(fg)
        .multilineTextAlignment(.center)
      Button(action: onRetry) {
        Text(DefaultResolveErrorCopy.retryLabel)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(buttonFg)
          .frame(minWidth: 140)
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
          .background(buttonBg)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      Text(DefaultResolveErrorCopy.hint)
        .font(.system(size: 13))
        .foregroundStyle(muted)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(24)
  }
}
