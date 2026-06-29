import Foundation

public struct SdkResolveRequest: Codable, Equatable, Sendable {
  public var identity: SdkIdentity
  public var context: SdkContext?
}

public struct ResolvedAppIntegrations: Codable, Equatable, Sendable {
  public var appsflyer: IntegrationEnabled?
  public var revenuecat: IntegrationEnabled?
  public var raw: [String: JSONValue]

  public init(appsflyer: IntegrationEnabled? = nil, revenuecat: IntegrationEnabled? = nil, raw: [String: JSONValue] = [:]) {
    self.appsflyer = appsflyer
    self.revenuecat = revenuecat
    self.raw = raw
  }

  private enum CodingKeys: String, CodingKey {
    case appsflyer
    case revenuecat
  }

  public init(from decoder: Decoder) throws {
    let value = try JSONValue(from: decoder)
    if case .object(let object) = value {
      raw = object
    } else {
      raw = [:]
    }
    let container = try decoder.container(keyedBy: CodingKeys.self)
    appsflyer = try container.decodeIfPresent(IntegrationEnabled.self, forKey: .appsflyer)
    revenuecat = try container.decodeIfPresent(IntegrationEnabled.self, forKey: .revenuecat)
  }

  public func encode(to encoder: Encoder) throws {
    try raw.encode(to: encoder)
  }
}

public struct IntegrationEnabled: Codable, Equatable, Sendable {
  public var enabled: Bool
}

public struct SdkResolveFeatures: Codable, Equatable, Sendable {
  public var attribution: Bool
}

public struct SdkResolveResponse: Codable, Equatable, Sendable {
  public var flowId: String
  public var versionId: String
  public var versionNumber: Int
  public var assignmentVersion: Int
  public var environment: String
  public var channelId: String
  public var experimentId: String?
  public var variantId: String?
  public var manifest: FlowManifest
  public var mediaMap: [String: URL]
  public var branding: Branding?
  public var features: SdkResolveFeatures?
  public var integrations: ResolvedAppIntegrations
}

/// Batch resolve response for `POST /v1/sdk/resolve-all` — one entry per assigned channel.
public struct SdkResolveAllResponse: Codable, Equatable, Sendable {
  public var channels: [SdkResolveResponse]
}
