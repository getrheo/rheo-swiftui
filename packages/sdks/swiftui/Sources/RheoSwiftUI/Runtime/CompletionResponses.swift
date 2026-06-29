import Foundation

public func stepResponseToCompletionValue(_ response: StepResponse) -> JSONValue? {
  switch response {
  case .choice(let choiceId):
    return .string(choiceId)
  case .multiChoice(let choiceIds):
    return .array(choiceIds.map { .string($0) })
  case .text(let value, _):
    return .string(value)
  case .scale(let value):
    return .number(value)
  case .checkbox(_, let value):
    return .bool(value)
  case .permissionOutcome(_, _, let outcome):
    return .string(outcome.rawValue)
  case .appReviewOutcome(_, let outcome):
    return .string(outcome.rawValue)
  case .externalSurfaceOutcome(_, let outcome, _):
    return .string(outcome.rawValue)
  case .bypassInput:
    return .null
  case .cta(let action):
    return .string(action)
  case .carousel:
    return .string("completed")
  case .skip:
    return .string("skipped")
  case .endFlow:
    return .string("ended")
  default:
    return nil
  }
}

public func isAuthTerminalExportResponseKey(_ key: String) -> Bool {
  key.hasPrefix("oauth:") || key.hasPrefix("email_pw:")
}

public func stripAuthResponsesForTerminalExport(_ responses: [String: StepResponse]) -> [String: StepResponse] {
  responses.filter { key, _ in !isAuthTerminalExportResponseKey(key) }
}

public func buildCompletionResponses(_ state: FlowState) -> [String: JSONValue] {
  var out: [String: JSONValue] = [:]
  for (key, response) in stripAuthResponsesForTerminalExport(state.responses) {
    if let value = stepResponseToCompletionValue(response) {
      out[key] = value
    }
  }
  return out
}

public func buildTerminalSnapshot(
  terminal: String,
  resolved: SdkResolveResponse,
  state: FlowState,
  subject: SdkIdentity,
  appVersion: String?,
  customProperties: [String: String],
  includeManifest: Bool,
  includePath: Bool,
  includeAnswerDetail: Bool
) -> FlowTerminalSnapshot {
  let strippedRaw = stripAuthResponsesForTerminalExport(state.responses)
  var answers: [String: JSONValue] = [:]
  for (key, response) in strippedRaw {
    if let value = stepResponseToCompletionValue(response) {
      answers[key] = value
    }
  }

  var visited = Set<String>()
  for id in state.history {
    if state.manifest.screen(id: id) != nil {
      visited.insert(id)
    }
  }
  if let current = state.currentScreenId, state.manifest.screen(id: current) != nil {
    visited.insert(current)
  }
  for screenId in visited {
    guard let screen = state.manifest.screen(id: screenId) else { continue }
    for key in collectAnswerCaptureFieldKeys(from: screen) where answers[key] == nil {
      answers[key] = .null
    }
  }

  let custom = customProperties.mapValues { JSONValue.string($0) }
  return FlowTerminalSnapshot(
    schemaVersion: 1,
    terminal: terminal,
    occurredAt: state.completedAt,
    correlation: FlowTerminalCorrelation(
      channelId: resolved.channelId,
      flowId: resolved.flowId,
      versionId: resolved.versionId,
      assignmentVersion: resolved.assignmentVersion,
      environment: resolved.environment,
      experimentId: resolved.experimentId,
      variantId: resolved.variantId
    ),
    subject: subject,
    device: FlowTerminalDevice(
      locale: state.session.locale,
      platform: state.session.platform,
      appVersion: appVersion,
      customProperties: custom.isEmpty ? nil : custom
    ),
    answers: answers,
    traits: state.session.sdkAttributes,
    path: includePath ? state.history : nil,
    answersDetail: includeAnswerDetail ? strippedRaw : nil,
    manifest: includeManifest ? resolved.manifest : nil
  )
}
