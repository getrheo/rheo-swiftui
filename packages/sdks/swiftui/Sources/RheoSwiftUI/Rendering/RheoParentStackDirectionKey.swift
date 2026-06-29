import SwiftUI

/// Direction of the immediate parent stack (`HStack` / `VStack`). Nil at
/// region roots and outside any stack. Mirrors the web sim's
/// `ctx.parentStackDirection` and React Native's environment value.
enum RheoParentStackDirection: Equatable, Sendable {
  case vertical
  case horizontal
}

struct RheoParentStackDirectionKey: EnvironmentKey {
  static var defaultValue: RheoParentStackDirection? = nil
}

extension EnvironmentValues {
  var rheoParentStackDirection: RheoParentStackDirection? {
    get { self[RheoParentStackDirectionKey.self] }
    set { self[RheoParentStackDirectionKey.self] = newValue }
  }
}
