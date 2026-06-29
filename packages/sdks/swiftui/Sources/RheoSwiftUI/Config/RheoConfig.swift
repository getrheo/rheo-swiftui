import Foundation

public enum RheoPlatform: String, Codable, Sendable {
  case ios
  case android
  case web
}

public struct RheoConfig: @unchecked Sendable {
  public var publishableKey: String
  public var apiBaseURL: URL
  public var userId: String?
  public var customUserId: String?
  public var sessionId: String?
  public var locale: String
  public var appVersion: String?
  public var platform: RheoPlatform
  public var sdkAttributes: [String: JSONValue]
  public var customProperties: [String: String]
  public var urlSession: URLSession

  public init(
    publishableKey: String,
    // Keep in sync with RHEO_DEFAULT_SDK_API_BASE_URL in @getrheo/contracts.
    apiBaseURL: URL = URL(string: "https://api.getrheo.io")!,
    userId: String? = nil,
    customUserId: String? = nil,
    sessionId: String? = nil,
    locale: String = Locale.current.identifier,
    appVersion: String? = nil,
    platform: RheoPlatform = .ios,
    sdkAttributes: [String: JSONValue] = [:],
    customProperties: [String: String] = [:],
    urlSession: URLSession = .shared
  ) {
    self.publishableKey = publishableKey
    self.apiBaseURL = apiBaseURL
    self.userId = userId
    self.customUserId = customUserId
    self.sessionId = sessionId
    self.locale = locale
    self.appVersion = appVersion
    self.platform = platform
    self.sdkAttributes = sdkAttributes
    self.customProperties = customProperties
    self.urlSession = urlSession
  }

  public func resolvedAppUserId() -> String {
    if let userId, !userId.isEmpty { return userId }
    let key = "rheo_app_user_id"
    if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
      return existing
    }
    let id = UUID().uuidString.lowercased()
    UserDefaults.standard.set(id, forKey: key)
    return id
  }
}
