import Foundation

public struct FlowTerminalCorrelation: Codable, Equatable, Sendable {
  public var channelId: String
  public var flowId: String
  public var versionId: String
  public var assignmentVersion: Int
  public var environment: String
  public var experimentId: String?
  public var variantId: String?
}

public struct FlowTerminalDevice: Codable, Equatable, Sendable {
  public var locale: String
  public var platform: String
  public var appVersion: String?
  public var customProperties: [String: JSONValue]?
}

public struct FlowTerminalSnapshot: Codable, Equatable, Sendable {
  public var schemaVersion: Int
  public var terminal: String
  public var occurredAt: String?
  public var correlation: FlowTerminalCorrelation
  public var subject: SdkIdentity
  public var device: FlowTerminalDevice
  public var answers: [String: JSONValue]
  public var traits: [String: JSONValue]
  public var path: [String]?
  public var answersDetail: [String: StepResponse]?
  public var manifest: FlowManifest?
}
