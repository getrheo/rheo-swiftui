import SwiftUI

public struct MotionController: Equatable, Sendable {
  public var screen: Screen

  public init(screen: Screen) {
    self.screen = screen
  }
}

private struct MotionControllerKey: EnvironmentKey {
  static let defaultValue: MotionController? = nil
}

extension EnvironmentValues {
  var motionController: MotionController? {
    get { self[MotionControllerKey.self] }
    set { self[MotionControllerKey.self] = newValue }
  }
}

public struct MotionProvider<Content: View>: View {
  public var screen: Screen
  @ViewBuilder public var content: () -> Content

  public init(
    screen: Screen,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.screen = screen
    self.content = content
  }

  public var body: some View {
    content()
      .environment(\.motionController, MotionController(screen: screen))
  }
}
