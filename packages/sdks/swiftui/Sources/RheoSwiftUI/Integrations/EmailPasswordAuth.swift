import Foundation

public struct EmailPasswordAuthResolveInput: Sendable {
  public var success: Bool
  public var error: JSONValue?

  public init(success: Bool, error: JSONValue? = nil) {
    self.success = success
    self.error = error
  }
}

public struct EmailPasswordAuthHandlerPayload: Sendable {
  public var manifest: FlowManifest
  public var screenId: String
  public var layerId: String
  public var fieldKey: String
  public var mode: EmailPasswordAuthMode
  public var email: String
  public var password: String
  public var confirmPassword: String?
  public var resolve: @Sendable (EmailPasswordAuthResolveInput) -> Void
}

public typealias EmailPasswordAuthHandler = @Sendable (EmailPasswordAuthHandlerPayload) -> Void
