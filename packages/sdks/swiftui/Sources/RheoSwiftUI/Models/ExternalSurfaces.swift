import Foundation

public enum NormalizedSurfaceOutcome: String, Codable, Sendable {
  case purchaseCompleted = "purchase_completed"
  case purchaseCancelled = "purchase_cancelled"
  case dismissed
  case failed
  case restoreCompleted = "restore_completed"
}

public enum ExternalSurfaceConfig: Codable, Equatable, Sendable {
  case unspecified
  case revenueCat(RevenueCatSurfaceConfig)
  case unknown(provider: String, payload: [String: JSONValue])

  private enum CodingKeys: String, CodingKey {
    case provider
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let provider = try container.decode(String.self, forKey: .provider)
    switch provider {
    case "unspecified":
      self = .unspecified
    case "revenuecat":
      self = .revenueCat(try RevenueCatSurfaceConfig(from: decoder))
    default:
      let raw = try JSONValue(from: decoder)
      if case .object(let object) = raw {
        self = .unknown(provider: provider, payload: object)
      } else {
        self = .unknown(provider: provider, payload: [:])
      }
    }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .unspecified:
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode("unspecified", forKey: .provider)
    case .revenueCat(let config):
      try config.encode(to: encoder)
    case .unknown(_, let payload):
      try payload.encode(to: encoder)
    }
  }

  public var provider: String {
    switch self {
    case .unspecified: return "unspecified"
    case .revenueCat: return "revenuecat"
    case .unknown(let provider, _): return provider
    }
  }
}

public struct RevenueCatSurfaceConfig: Codable, Equatable, Sendable {
  public var provider: String
  public var offeringId: String?
  public var placementId: String?
  public var presentation: String?
}

public struct ExternalSurfaceNode: Codable, Equatable, Sendable {
  public var id: String
  public var name: String?
  public var config: ExternalSurfaceConfig
  public var outcomes: [String: String?]
  public var fallback: String?
}

/// Commerce details for a successful in-app purchase. Forwarded by the SDK
/// onto the `iap_purchase` analytics event. Fields are best-effort — when the
/// host RevenueCat presenter cannot read price metadata, individual fields
/// may be missing.
public struct RevenueCatPurchaseCommerce: Sendable, Equatable {
  public var productId: String
  public var offeringId: String?
  public var packageId: String?
  public var price: Double?
  public var currency: String?
  public var periodType: String?

  public init(
    productId: String,
    offeringId: String? = nil,
    packageId: String? = nil,
    price: Double? = nil,
    currency: String? = nil,
    periodType: String? = nil
  ) {
    self.productId = productId
    self.offeringId = offeringId
    self.packageId = packageId
    self.price = price
    self.currency = currency
    self.periodType = periodType
  }
}

public struct ExternalSurfaceResult: Sendable {
  public var outcome: NormalizedSurfaceOutcome
  public var sdkKeyPatch: [String: JSONValue]
  /// Set when `outcome == .purchaseCompleted` and the presenter was able to
  /// read commerce metadata. Used to populate the `iap_purchase` event.
  public var commerce: RevenueCatPurchaseCommerce?

  public init(
    outcome: NormalizedSurfaceOutcome,
    sdkKeyPatch: [String: JSONValue] = [:],
    commerce: RevenueCatPurchaseCommerce? = nil
  ) {
    self.outcome = outcome
    self.sdkKeyPatch = sdkKeyPatch
    self.commerce = commerce
  }
}
