import Foundation

public struct SdkLogger: Sendable {
  public let level: SdkLogLevel

  public init(level: SdkLogLevel) {
    self.level = level
  }

  public func warn(_ message: String) {
    guard level == .warn || level == .debug else { return }
    print(message)
  }

  public func debug(_ message: String) {
    #if DEBUG
      guard level == .debug else { return }
      print(message)
    #endif
  }

  public static let silent = SdkLogger(level: .silent)
}
