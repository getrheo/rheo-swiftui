import Foundation

public indirect enum StepResponse: Codable, Equatable, Sendable {
  case choice(choiceId: String)
  case multiChoice(choiceIds: [String])
  case text(value: String, classification: String)
  case scale(value: Double)
  case checkbox(fieldKey: String, value: Bool)
  case cta(action: String)
  case carousel
  case skip(consumedDraft: StepResponse?)
  case endFlow(consumedDraft: StepResponse?)
  case bypassInput(via: String)
  case goToScreen(screenId: String)
  case permissionOutcome(layerId: String, permissionKey: OSPermissionKey, outcome: PermissionOutcome)
  case appReviewOutcome(layerId: String, outcome: AppReviewOutcome)
  case oauthLoginResolve(layerId: String, provider: OAuthProvider, success: Bool, customerExternalId: String?, error: JSONValue?)
  case emailPasswordAuthResolve(layerId: String, fieldKey: String, mode: EmailPasswordAuthMode, email: String, password: String, confirmPassword: String?, success: Bool, error: JSONValue?)
  case externalSurfaceOutcome(nodeId: String, outcome: NormalizedSurfaceOutcome, sdkKeyPatch: [String: JSONValue]?)
  case goBack(fallbackScreenId: String?)
  case screenCommit(primary: StepResponse, checkboxValues: [String: Bool], capturedDraft: StepResponse?)

  private enum CodingKeys: String, CodingKey {
    case kind
    case choiceId
    case choiceIds
    case value
    case classification
    case fieldKey
    case action
    case consumedDraft
    case via
    case screenId
    case layerId
    case permissionKey
    case outcome
    case provider
    case success
    case customerExternalId
    case error
    case mode
    case email
    case password
    case confirmPassword
    case nodeId
    case sdkKeyPatch
    case fallbackScreenId
    case primary
    case checkboxValues
    case capturedDraft
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(String.self, forKey: .kind)
    switch kind {
    case "choice":
      self = .choice(choiceId: try container.decode(String.self, forKey: .choiceId))
    case "multiChoice":
      self = .multiChoice(choiceIds: try container.decode([String].self, forKey: .choiceIds))
    case "text":
      self = .text(value: try container.decode(String.self, forKey: .value), classification: try container.decode(String.self, forKey: .classification))
    case "scale":
      self = .scale(value: try container.decode(Double.self, forKey: .value))
    case "checkbox":
      self = .checkbox(fieldKey: try container.decode(String.self, forKey: .fieldKey), value: try container.decode(Bool.self, forKey: .value))
    case "cta":
      self = .cta(action: try container.decode(String.self, forKey: .action))
    case "carousel":
      self = .carousel
    case "skip":
      self = .skip(consumedDraft: try container.decodeIfPresent(StepResponse.self, forKey: .consumedDraft))
    case "end_flow":
      self = .endFlow(consumedDraft: try container.decodeIfPresent(StepResponse.self, forKey: .consumedDraft))
    case "bypass_input":
      self = .bypassInput(via: try container.decode(String.self, forKey: .via))
    case "go_to_screen":
      self = .goToScreen(screenId: try container.decode(String.self, forKey: .screenId))
    case "permission_outcome":
      self = .permissionOutcome(
        layerId: try container.decode(String.self, forKey: .layerId),
        permissionKey: try container.decode(String.self, forKey: .permissionKey),
        outcome: try container.decode(PermissionOutcome.self, forKey: .outcome)
      )
    case "app_review_outcome":
      self = .appReviewOutcome(
        layerId: try container.decode(String.self, forKey: .layerId),
        outcome: try container.decode(AppReviewOutcome.self, forKey: .outcome)
      )
    case "oauth_login_resolve":
      self = .oauthLoginResolve(
        layerId: try container.decode(String.self, forKey: .layerId),
        provider: try container.decode(OAuthProvider.self, forKey: .provider),
        success: try container.decode(Bool.self, forKey: .success),
        customerExternalId: try container.decodeIfPresent(String.self, forKey: .customerExternalId),
        error: try container.decodeIfPresent(JSONValue.self, forKey: .error)
      )
    case "email_password_auth_resolve":
      self = .emailPasswordAuthResolve(
        layerId: try container.decode(String.self, forKey: .layerId),
        fieldKey: try container.decode(String.self, forKey: .fieldKey),
        mode: try container.decode(EmailPasswordAuthMode.self, forKey: .mode),
        email: try container.decode(String.self, forKey: .email),
        password: try container.decode(String.self, forKey: .password),
        confirmPassword: try container.decodeIfPresent(String.self, forKey: .confirmPassword),
        success: try container.decode(Bool.self, forKey: .success),
        error: try container.decodeIfPresent(JSONValue.self, forKey: .error)
      )
    case "external_surface_outcome":
      self = .externalSurfaceOutcome(
        nodeId: try container.decode(String.self, forKey: .nodeId),
        outcome: try container.decode(NormalizedSurfaceOutcome.self, forKey: .outcome),
        sdkKeyPatch: try container.decodeIfPresent([String: JSONValue].self, forKey: .sdkKeyPatch)
      )
    case "go_back":
      self = .goBack(fallbackScreenId: try container.decodeIfPresent(String.self, forKey: .fallbackScreenId))
    case "screen_commit":
      self = .screenCommit(
        primary: try container.decode(StepResponse.self, forKey: .primary),
        checkboxValues: try container.decode([String: Bool].self, forKey: .checkboxValues),
        capturedDraft: try container.decodeIfPresent(StepResponse.self, forKey: .capturedDraft)
      )
    default:
      throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown step response kind \(kind)")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .choice(let choiceId):
      try container.encode("choice", forKey: .kind)
      try container.encode(choiceId, forKey: .choiceId)
    case .multiChoice(let choiceIds):
      try container.encode("multiChoice", forKey: .kind)
      try container.encode(choiceIds, forKey: .choiceIds)
    case .text(let value, let classification):
      try container.encode("text", forKey: .kind)
      try container.encode(value, forKey: .value)
      try container.encode(classification, forKey: .classification)
    case .scale(let value):
      try container.encode("scale", forKey: .kind)
      try container.encode(value, forKey: .value)
    case .checkbox(let fieldKey, let value):
      try container.encode("checkbox", forKey: .kind)
      try container.encode(fieldKey, forKey: .fieldKey)
      try container.encode(value, forKey: .value)
    case .cta(let action):
      try container.encode("cta", forKey: .kind)
      try container.encode(action, forKey: .action)
    case .carousel:
      try container.encode("carousel", forKey: .kind)
    case .skip(let consumedDraft):
      try container.encode("skip", forKey: .kind)
      try container.encodeIfPresent(consumedDraft, forKey: .consumedDraft)
    case .endFlow(let consumedDraft):
      try container.encode("end_flow", forKey: .kind)
      try container.encodeIfPresent(consumedDraft, forKey: .consumedDraft)
    case .bypassInput(let via):
      try container.encode("bypass_input", forKey: .kind)
      try container.encode(via, forKey: .via)
    case .goToScreen(let screenId):
      try container.encode("go_to_screen", forKey: .kind)
      try container.encode(screenId, forKey: .screenId)
    case .permissionOutcome(let layerId, let permissionKey, let outcome):
      try container.encode("permission_outcome", forKey: .kind)
      try container.encode(layerId, forKey: .layerId)
      try container.encode(permissionKey, forKey: .permissionKey)
      try container.encode(outcome, forKey: .outcome)
    case .appReviewOutcome(let layerId, let outcome):
      try container.encode("app_review_outcome", forKey: .kind)
      try container.encode(layerId, forKey: .layerId)
      try container.encode(outcome, forKey: .outcome)
    case .oauthLoginResolve(let layerId, let provider, let success, let customerExternalId, let error):
      try container.encode("oauth_login_resolve", forKey: .kind)
      try container.encode(layerId, forKey: .layerId)
      try container.encode(provider, forKey: .provider)
      try container.encode(success, forKey: .success)
      try container.encodeIfPresent(customerExternalId, forKey: .customerExternalId)
      try container.encodeIfPresent(error, forKey: .error)
    case .emailPasswordAuthResolve(let layerId, let fieldKey, let mode, let email, let password, let confirmPassword, let success, let error):
      try container.encode("email_password_auth_resolve", forKey: .kind)
      try container.encode(layerId, forKey: .layerId)
      try container.encode(fieldKey, forKey: .fieldKey)
      try container.encode(mode, forKey: .mode)
      try container.encode(email, forKey: .email)
      try container.encode(password, forKey: .password)
      try container.encodeIfPresent(confirmPassword, forKey: .confirmPassword)
      try container.encode(success, forKey: .success)
      try container.encodeIfPresent(error, forKey: .error)
    case .externalSurfaceOutcome(let nodeId, let outcome, let sdkKeyPatch):
      try container.encode("external_surface_outcome", forKey: .kind)
      try container.encode(nodeId, forKey: .nodeId)
      try container.encode(outcome, forKey: .outcome)
      try container.encodeIfPresent(sdkKeyPatch, forKey: .sdkKeyPatch)
    case .goBack(let fallbackScreenId):
      try container.encode("go_back", forKey: .kind)
      try container.encodeIfPresent(fallbackScreenId, forKey: .fallbackScreenId)
    case .screenCommit(let primary, let checkboxValues, let capturedDraft):
      try container.encode("screen_commit", forKey: .kind)
      try container.encode(primary, forKey: .primary)
      try container.encode(checkboxValues, forKey: .checkboxValues)
      try container.encodeIfPresent(capturedDraft, forKey: .capturedDraft)
    }
  }
}

extension StepResponse {
  public var kind: String {
    switch self {
    case .choice: return "choice"
    case .multiChoice: return "multiChoice"
    case .text: return "text"
    case .scale: return "scale"
    case .checkbox: return "checkbox"
    case .cta: return "cta"
    case .carousel: return "carousel"
    case .skip: return "skip"
    case .endFlow: return "end_flow"
    case .bypassInput: return "bypass_input"
    case .goToScreen: return "go_to_screen"
    case .permissionOutcome: return "permission_outcome"
    case .appReviewOutcome: return "app_review_outcome"
    case .oauthLoginResolve: return "oauth_login_resolve"
    case .emailPasswordAuthResolve: return "email_password_auth_resolve"
    case .externalSurfaceOutcome: return "external_surface_outcome"
    case .goBack: return "go_back"
    case .screenCommit: return "screen_commit"
    }
  }

  public var eligibleConsumedDraft: StepResponse? {
    switch self {
    case .choice, .multiChoice, .text, .scale, .cta, .carousel:
      return self
    default:
      return nil
    }
  }
}
