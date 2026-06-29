import Foundation

public enum EventName: String, Codable, Sendable {
  case flowStarted = "flow_started"
  case stepViewed = "step_viewed"
  case stepCompleted = "step_completed"
  case stepSkipped = "step_skipped"
  case choiceSelected = "choice_selected"
  case textSubmitted = "text_submitted"
  case flowCompleted = "flow_completed"
  case flowAbandoned = "flow_abandoned"
  case decisionEvaluated = "decision_evaluated"
  case externalLinkOpened = "external_link_opened"
  case surfacePresented = "surface_presented"
  case surfaceOutcome = "surface_outcome"
  case appReviewPromptShown = "app_review_prompt_shown"
  case appReviewPromptDismissed = "app_review_prompt_dismissed"
  case attributionContextObserved = "attribution_context_observed"
  case iapPurchase = "iap_purchase"
}

public struct SdkIdentity: Codable, Equatable, Sendable {
  public var appUserId: String
  public var customUserId: String?
  public var sessionId: String?
}

public struct SdkContext: Codable, Equatable, Sendable {
  public var platform: RheoPlatform?
  public var appVersion: String?
  public var locale: String?
  public var customProperties: [String: JSONValue]?
}

public struct SdkEvent: Codable, Equatable, Sendable {
  public var eventId: String
  public var name: EventName
  public var timestamp: String
  public var flowId: String
  public var versionId: String
  public var experimentId: String?
  public var variantId: String?
  public var stepId: String?
  public var identity: SdkIdentity
  public var context: SdkContext?
  public var properties: [String: JSONValue]?
  public var fieldClassification: String?
}

public struct SdkEventBatch: Codable, Equatable, Sendable {
  public var events: [SdkEvent]
}

public struct TrackEventInput: Sendable {
  public var name: EventName
  public var flowId: String
  public var versionId: String
  public var experimentId: String?
  public var variantId: String?
  public var stepId: String?
  public var properties: [String: JSONValue]?
  public var fieldClassification: String?
  public var timestamp: String?

  public init(
    name: EventName,
    flowId: String,
    versionId: String,
    experimentId: String? = nil,
    variantId: String? = nil,
    stepId: String? = nil,
    properties: [String: JSONValue]? = nil,
    fieldClassification: String? = nil,
    timestamp: String? = nil
  ) {
    self.name = name
    self.flowId = flowId
    self.versionId = versionId
    self.experimentId = experimentId
    self.variantId = variantId
    self.stepId = stepId
    self.properties = properties
    self.fieldClassification = fieldClassification
    self.timestamp = timestamp
  }
}
