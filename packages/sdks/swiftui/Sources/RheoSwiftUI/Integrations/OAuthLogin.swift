import Foundation

public struct OAuthLoginResolveInput: Sendable {
  public var success: Bool
  public var customerExternalId: String?
  public var error: JSONValue?

  public init(success: Bool, customerExternalId: String? = nil, error: JSONValue? = nil) {
    self.success = success
    self.customerExternalId = customerExternalId
    self.error = error
  }
}

public struct OAuthLoginHandlerPayload: Sendable {
  public var manifest: FlowManifest
  public var screenId: String
  public var layerId: String
  public var provider: OAuthProvider
  public var resolve: @Sendable (OAuthLoginResolveInput) -> Void
}

public typealias OAuthLoginHandler = @Sendable (OAuthLoginHandlerPayload) -> Void
