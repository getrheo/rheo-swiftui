import Foundation

/// Keep values in sync with `SdkLogLevelSchema` in `@getrheo/contracts`.
public enum SdkLogLevel: String, Sendable {
  case silent
  case warn
  case debug

  public static let `default`: SdkLogLevel = .silent
}
