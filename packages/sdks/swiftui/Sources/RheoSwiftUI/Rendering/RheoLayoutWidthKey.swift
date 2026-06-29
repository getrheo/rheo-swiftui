import SwiftUI

struct RheoLayoutWidthKey: EnvironmentKey {
  static var defaultValue: CGFloat?
}

extension EnvironmentValues {
  var rheoLayoutWidth: CGFloat? {
    get { self[RheoLayoutWidthKey.self] }
    set { self[RheoLayoutWidthKey.self] = newValue }
  }
}
