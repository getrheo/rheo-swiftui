import Foundation

enum URLRequestFactory {
  static func resolveRequest(
    config: RheoConfig,
    channelId: String,
    ifNoneMatch: String? = nil
  ) throws -> URLRequest {
    let url = config.apiBaseURL.appendingPathComponent("v1/sdk/resolve")
    let body = SdkResolveRequest(
      identity: SdkIdentity(
        appUserId: config.resolvedAppUserId(),
        customUserId: config.customUserId,
        sessionId: config.sessionId
      ),
      context: SdkContext(
        platform: nil,
        appVersion: nil,
        locale: config.locale,
        customProperties: nil
      )
    )
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(config.publishableKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(channelId, forHTTPHeaderField: "X-Rheo-Channel")
    if let ifNoneMatch, !ifNoneMatch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      request.setValue(ifNoneMatch, forHTTPHeaderField: "If-None-Match")
    }
    request.httpBody = try JSONEncoder.rheo.encode(body)
    return request
  }

  static func resolveAllRequest(config: RheoConfig) throws -> URLRequest {
    let url = config.apiBaseURL.appendingPathComponent("v1/sdk/resolve-all")
    let body = SdkResolveRequest(
      identity: SdkIdentity(
        appUserId: config.resolvedAppUserId(),
        customUserId: config.customUserId,
        sessionId: config.sessionId
      ),
      context: SdkContext(
        platform: nil,
        appVersion: nil,
        locale: config.locale,
        customProperties: nil
      )
    )
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(config.publishableKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder.rheo.encode(body)
    return request
  }

  static func eventsRequest(
    config: RheoConfig,
    channelId: String,
    events: [SdkEvent]
  ) throws -> URLRequest {
    let url = config.apiBaseURL.appendingPathComponent("v1/sdk/events")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(config.publishableKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(channelId, forHTTPHeaderField: "X-Rheo-Channel")
    request.httpBody = try JSONEncoder.rheo.encode(SdkEventBatch(events: events))
    return request
  }
}
