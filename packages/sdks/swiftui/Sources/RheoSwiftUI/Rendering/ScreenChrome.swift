import SwiftUI

public struct ScreenChrome<Content: View>: View {
  public var theme: ThemeMode
  public var content: Content

  public init(theme: ThemeMode, @ViewBuilder content: () -> Content) {
    self.theme = theme
    self.content = content()
  }

  public var body: some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
