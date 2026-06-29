import SwiftUI
import UIKit

enum OAuthPresetImageLoader {
  static func uiImage(named name: String) -> UIImage? {
    if let image = UIImage(named: name, in: .module, compatibleWith: nil) {
      return image
    }
    guard let url = Bundle.module.url(forResource: name, withExtension: "png") else {
      return nil
    }
    return UIImage(contentsOfFile: url.path)
  }
}
