import Foundation

public struct FlowSessionContext: Codable, Equatable, Sendable {
  public var locale: String
  public var platform: String
  public var sdkAttributes: [String: JSONValue]
}

public struct PendingExternalSurface: Codable, Equatable, Sendable {
  public var nodeId: String
}

public enum FlowStatus: String, Codable, Sendable {
  case idle
  case running
  case completed
  case abandoned
}

public struct FlowState: Codable, Equatable, Sendable {
  public var manifest: FlowManifest
  public var currentScreenId: String?
  public var pendingExternalSurface: PendingExternalSurface?
  public var history: [String]
  public var responses: [String: StepResponse]
  public var session: FlowSessionContext
  public var status: FlowStatus
  public var startedAt: String?
  public var completedAt: String?
}

public func initFlowState(
  manifest: FlowManifest,
  locale: String? = nil,
  platform: String = "ios",
  sdkAttributes: [String: JSONValue] = [:]
) -> FlowState {
  FlowState(
    manifest: manifest,
    currentScreenId: nil,
    pendingExternalSurface: nil,
    history: [],
    responses: [:],
    session: FlowSessionContext(
      locale: locale ?? manifest.defaultLocale,
      platform: platform,
      sdkAttributes: sdkAttributes
    ),
    status: .idle,
    startedAt: nil,
    completedAt: nil
  )
}
