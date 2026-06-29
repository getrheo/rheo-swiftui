import Foundation

public let osPermissionOutcomeContinue = "continue"
public let osPermissionOutcomeEnd = "end"
public let externalSurfaceNoNext = "__onb_surface_no_next__"

public enum GraphLanding: Equatable, Sendable {
  case screen(String)
  case surface(String)
  case end
}

public func startFlow(
  _ state: FlowState,
  now: String = ISO8601DateFormatter.rheo.string(from: Date()),
  onDecisionEvaluated: ((DecisionEvaluationTelemetry) -> Void)? = nil
) -> FlowState {
  guard let entry = state.manifest.entryScreenId else {
    var next = state
    next.status = .idle
    next.currentScreenId = nil
    next.pendingExternalSurface = nil
    next.history = []
    next.startedAt = nil
    next.completedAt = nil
    return next
  }

  let landing = resolveThroughGraph(
    manifest: state.manifest,
    cursor: entry,
    responses: [:],
    session: state.session,
    onDecisionEvaluated: onDecisionEvaluated
  )

  var next = state
  next.status = .running
  next.startedAt = now
  switch landing {
  case .end:
    next.status = .completed
    next.currentScreenId = nil
    next.pendingExternalSurface = nil
    next.history = [entry]
    next.completedAt = now
  case .surface(let nodeId):
    next.currentScreenId = nil
    next.pendingExternalSurface = PendingExternalSurface(nodeId: nodeId)
    next.history = [nodeId]
  case .screen(let screenId):
    next.currentScreenId = screenId
    next.pendingExternalSurface = nil
    next.history = [screenId]
  }
  return next
}

public func abandonFlow(
  _ state: FlowState,
  now: String = ISO8601DateFormatter.rheo.string(from: Date())
) -> FlowState {
  guard state.status == .running else { return state }
  var next = state
  next.status = .abandoned
  next.completedAt = now
  return next
}

public func submitResponse(
  _ state: FlowState,
  response: StepResponse,
  now: String = ISO8601DateFormatter.rheo.string(from: Date()),
  onDecisionEvaluated: ((DecisionEvaluationTelemetry) -> Void)? = nil
) -> FlowState {
  guard state.status == .running else { return state }

  if case .externalSurfaceOutcome(let nodeId, let outcome, let sdkKeyPatch) = response {
    guard state.pendingExternalSurface?.nodeId == nodeId,
          let surface = state.manifest.externalSurface(id: nodeId) else {
      return state
    }
    var nextSession = state.session
    if let sdkKeyPatch {
      nextSession.sdkAttributes.merge(sdkKeyPatch) { _, new in new }
    }
    var nextResponses = state.responses
    nextResponses[externalSurfaceResponseKey(nodeId)] = response
    let target = (surface.outcomes[outcome.rawValue] ?? nil) ?? surface.fallback
    var base = state
    base.session = nextSession
    if target == externalSurfaceNoNext {
      base.responses = nextResponses
      base.pendingExternalSurface = nil
      base.currentScreenId = nil
      base.status = .completed
      base.completedAt = now
      return base
    }
    let landing = resolveThroughGraph(
      manifest: state.manifest,
      cursor: target ?? nil,
      responses: nextResponses,
      session: nextSession,
      onDecisionEvaluated: onDecisionEvaluated
    )
    return applyGraphLanding(base: base, landing: landing, responses: nextResponses, now: now)
  }

  guard let currentScreenId = state.currentScreenId,
        let screen = state.manifest.screen(id: currentScreenId) else {
    return state
  }

  if case .screenCommit(let primary, let checkboxValues, let capturedDraft) = response {
    var merged = state
    for (fieldKey, value) in checkboxValues {
      merged.responses[fieldKey] = .checkbox(fieldKey: fieldKey, value: value)
    }
    if let capturedDraft, let screen = state.manifest.screen(id: currentScreenId) {
      merged.responses[responseKey(for: screen, response: capturedDraft)] = capturedDraft
    }
    return submitResponse(merged, response: primary, now: now, onDecisionEvaluated: onDecisionEvaluated)
  }

  if case .goBack(let fallbackScreenId) = response {
    if state.history.count > 1 {
      var next = state
      next.history = Array(state.history.dropLast())
      next.currentScreenId = next.history.last
      next.pendingExternalSurface = nil
      return next
    }
    if let fallbackScreenId, state.manifest.screen(id: fallbackScreenId) != nil {
      var next = state
      next.currentScreenId = fallbackScreenId
      next.pendingExternalSurface = nil
      next.history = [fallbackScreenId]
      return next
    }
    return state
  }

  if case .oauthLoginResolve(let layerId, _, let success, _, _) = response, !success {
    var next = state
    next.responses[oauthLoginResponseKey(layerId)] = response
    return next
  }

  if case .emailPasswordAuthResolve(let layerId, _, _, _, _, _, let success, _) = response, !success {
    var next = state
    next.responses[emailPasswordAuthResponseKey(layerId)] = response
    return next
  }

  if case .endFlow(let consumedDraft) = response {
    var next = state
    if let consumedDraft {
      next.responses[responseKey(for: screen, response: consumedDraft)] = consumedDraft
    }
    next.responses[responseKey(for: screen, response: response)] = .endFlow(consumedDraft: nil)
    next.currentScreenId = nil
    next.pendingExternalSurface = nil
    next.status = .completed
    next.completedAt = now
    return next
  }

  if case .skip = response {
    var nextResponses = state.responses
    if let manual = findManualSubmitInputLayer(screen) {
      nextResponses[inputFieldKey(manual)] = .bypassInput(via: "skip")
    }
    nextResponses[responseKey(for: screen, response: response)] = .skip(consumedDraft: nil)
    let nextRaw = resolveNextScreenId(screen: screen, response: response)
    let landing = resolveThroughGraph(
      manifest: state.manifest,
      cursor: nextRaw,
      responses: nextResponses,
      session: state.session,
      onDecisionEvaluated: onDecisionEvaluated
    )
    return applyGraphLanding(base: state, landing: landing, responses: nextResponses, now: now)
  }

  var nextResponses = state.responses
  nextResponses[responseKey(for: screen, response: response)] = response
  if case .goToScreen = response, let manual = findManualSubmitInputLayer(screen) {
    nextResponses[inputFieldKey(manual)] = .bypassInput(via: "go_to_screen")
  }
  let nextRaw = resolveNextScreenId(screen: screen, response: response)
  let landing = resolveThroughGraph(
    manifest: state.manifest,
    cursor: nextRaw,
    responses: nextResponses,
    session: state.session,
    onDecisionEvaluated: onDecisionEvaluated
  )
  return applyGraphLanding(base: state, landing: landing, responses: nextResponses, now: now)
}

public func resolveNextScreenId(screen: Screen, response: StepResponse) -> FlowJumpTarget {
  if case .screenCommit(let primary, _, _) = response {
    return resolveNextScreenId(screen: screen, response: primary)
  }
  if case .appReviewOutcome(let layerId, _) = response {
    if let layer = findLayerById(screen, layerId),
       case .button(let button) = layer,
       case .requestAppReview = button.action {
      return screen.next.default
    }
    return screen.next.default
  }
  if case .goToScreen(let screenId) = response {
    return screenId
  }
  if case .permissionOutcome(let layerId, let permissionKey, let outcome) = response {
    if let layer = findLayerById(screen, layerId),
       case .button(let button) = layer,
       case .requestOSPermission(let key, let outcomes) = button.action,
       key == permissionKey {
      let target: String
      switch outcome {
      case .granted: target = outcomes.granted
      case .denied: target = outcomes.denied
      case .blocked: target = outcomes.blocked
      }
      if target == osPermissionOutcomeEnd { return nil }
      if target == osPermissionOutcomeContinue { return screen.next.default }
      return target
    }
    return screen.next.default
  }
  if case .oauthLoginResolve = response { return screen.next.default }
  if case .emailPasswordAuthResolve = response { return screen.next.default }

  if let input = findInputLayer(screen) {
    switch (input, response) {
    case (.singleChoice(let layer), .choice(let choiceId)) where layer.branching.enabled:
      return layer.branching.conditions.first { $0.choiceId == choiceId }?.goTo ?? screen.next.default
    case (.multipleChoice(let layer), .multiChoice(let choiceIds)) where layer.branching.enabled:
      return layer.branching.conditions.first { choiceIds.contains($0.choiceId) }?.goTo ?? screen.next.default
    default:
      break
    }
  }
  return screen.next.default
}

public func resolveThroughGraph(
  manifest: FlowManifest,
  cursor: FlowJumpTarget,
  responses: [String: StepResponse],
  session: FlowSessionContext,
  onDecisionEvaluated: ((DecisionEvaluationTelemetry) -> Void)? = nil
) -> GraphLanding {
  var cur = cursor
  while let id = cur {
    guard let decision = manifest.decisionNode(id: id) else { break }
    let result = evaluateDecisionNode(
      decision,
      context: DecisionEvaluationContext(
        locale: session.locale,
        platform: session.platform,
        sdkAttributes: session.sdkAttributes,
        responses: responses
      )
    )
    onDecisionEvaluated?(
      DecisionEvaluationTelemetry(
        decisionNodeId: decision.id,
        matchedCaseId: result.matchedCaseId,
        clauseDigest: result.clauseDigest
      )
    )
    cur = result.next
  }

  guard let id = cur else { return .end }
  if manifest.externalSurface(id: id) != nil { return .surface(id) }
  return .screen(id)
}

public func applyGraphLanding(
  base: FlowState,
  landing: GraphLanding,
  responses: [String: StepResponse],
  now: String
) -> FlowState {
  var next = base
  next.responses = responses
  switch landing {
  case .end:
    next.currentScreenId = nil
    next.pendingExternalSurface = nil
    next.status = .completed
    next.completedAt = now
  case .surface(let nodeId):
    next.currentScreenId = nil
    next.pendingExternalSurface = PendingExternalSurface(nodeId: nodeId)
    next.history.append(nodeId)
  case .screen(let screenId):
    next.currentScreenId = screenId
    next.pendingExternalSurface = nil
    next.history.append(screenId)
  }
  return next
}

public func responseKey(for screen: Screen, response: StepResponse) -> String {
  switch response {
  case .text, .choice, .multiChoice, .scale:
    if let input = findInputLayer(screen) {
      return inputFieldKey(input)
    }
  case .checkbox(let fieldKey, _):
    return fieldKey
  case .permissionOutcome(_, let permissionKey, _):
    return permissionCaptureFieldKey(permissionKey)
  case .appReviewOutcome(let layerId, _):
    return appReviewCaptureFieldKey(layerId)
  case .oauthLoginResolve(let layerId, _, _, _, _):
    return oauthLoginResponseKey(layerId)
  case .emailPasswordAuthResolve(let layerId, _, _, _, _, _, _, _):
    return emailPasswordAuthResponseKey(layerId)
  default:
    break
  }
  return screen.id
}

public func inputFieldKey(_ layer: Layer) -> String {
  switch layer {
  case .singleChoice(let layer): return layer.fieldKey
  case .multipleChoice(let layer): return layer.fieldKey
  case .textInput(let layer): return layer.fieldKey
  case .scaleInput(let layer): return layer.fieldKey
  default: return ""
  }
}

extension ISO8601DateFormatter {
  public static let rheo: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()
}
