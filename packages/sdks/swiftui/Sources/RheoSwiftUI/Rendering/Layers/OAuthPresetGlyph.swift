import SwiftUI
import UIKit

struct OAuthPresetGlyph: View {
  var preset: OAuthLoginPreset
  var color: Color
  var size: CGFloat = 22

  var body: some View {
    switch preset {
    case .apple:
      Image(systemName: "apple.logo")
        .font(.system(size: size, weight: .medium))
        .foregroundStyle(color)
    case .google:
      oauthPresetImage("logo-google")
    case .github:
      oauthPresetImage("logo-github")
    }
  }

  @ViewBuilder
  private func oauthPresetImage(_ name: String) -> some View {
    if let uiImage = OAuthPresetImageLoader.uiImage(named: name) {
      Image(uiImage: uiImage)
        .renderingMode(.template)
        .resizable()
        .interpolation(.high)
        .antialiased(true)
        .scaledToFit()
        .frame(width: size, height: size)
        .foregroundStyle(color)
    } else {
      oauthPresetFallback(name)
    }
  }

  @ViewBuilder
  private func oauthPresetFallback(_ name: String) -> some View {
    let symbol = name == "logo-google" ? "g.circle.fill" : "chevron.left.forwardslash.chevron.right"
    Image(systemName: symbol)
      .font(.system(size: size, weight: .medium))
      .foregroundStyle(color)
  }
}
