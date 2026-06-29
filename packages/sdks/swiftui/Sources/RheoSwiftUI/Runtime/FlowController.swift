import Foundation
import SwiftUI

@MainActor
public final class FlowController: ObservableObject {
  @Published public private(set) var loading = true
  @Published public private(set) var error: Error?
  @Published public private(set) var state: FlowState?
  @Published public private(set) var resolved: SdkResolveResponse?
  public let channelId: String
  private let runtime: RheoRuntime
  private let includeManifestInTerminalPayload: Bool
  private let includePathInTerminalPayload: Bool
  private let includeAnswerDetailInTerminalPayload: Bool
  private let onFlowCompleted: (@Sendable (FlowTerminalSnapshot) -> Void)?
  private let onFlowAbandoned: (@Sendable (FlowTerminalSnapshot) -> Void)?
  private let externalSurfacePresenter: ExternalSurfacePresenter
  private let attributionRuntime: AttributionRuntime?

  private var started = false
  private var seeded = false
  private var lastViewedScreenId: String?
  private var terminalHandledKey = ""
  private var presentedSurfaceId: String?
  private var attributionUnsubscribe: (@Sendable () -> Void)?

  public init(
    channelId: String,
    runtime: RheoRuntime,
    includeManifestInTerminalPayload: Bool = false,
    includePathInTerminalPayload: Bool = false,
    includeAnswerDetailInTerminalPayload: Bool = false,
    externalSurfacePresenter: @escaping ExternalSurfacePresenter = defaultExternalSurfacePresenter,
    attributionProviders: [AttributionProvider] = [],
    onFlowCompleted: (@Sendable (FlowTerminalSnapshot) -> Void)? = nil,
    onFlowAbandoned: (@Sendable (FlowTerminalSnapshot) -> Void)? = nil
  ) {
    self.channelId = channelId
    self.runtime = runtime
    self.includeManifestInTerminalPayload = includeManifestInTerminalPayload
    self.includePathInTerminalPayload = includePathInTerminalPayload
    self.includeAnswerDetailInTerminalPayload = includeAnswerDetailInTerminalPayload
    self.externalSurfacePresenter = externalSurfacePresenter
    self.attributionRuntime = attributionProviders.isEmpty ? nil : AttributionRuntime(providers: attributionProviders)
    self.onFlowCompleted = onFlowCompleted
    self.onFlowAbandoned = onFlowAbandoned
  }

  public var screen: Screen? {
    guard let state, let id = state.currentScreenId else { return nil }
    return state.manifest.screen(id: id)
  }

  public var manifest: FlowManifest? {
    resolved?.manifest
  }

  public var branding: Branding? {
    resolved?.branding
  }

  public var mediaMap: [String: URL] {
    resolved?.mediaMap ?? [:]
  }

  public var customProperties: [String: String] {
    runtime.config.customProperties
  }

  /// True when resolve failed and no manifest was loaded.
  public var resolveFailed: Bool {
    !loading && error != nil && resolved == nil
  }

  public func load() {
    Task { await resolve() }
  }

  public func retry() async {
    seeded = false
    await resolve()
  }

  /// Synchronously seed the running flow from a prefetched manifest in the cache
  /// so a warm mount renders immediately instead of flashing a `ProgressView`.
  /// No-ops on a cache miss; `resolve()` then revalidates in the background.
  public func seedFromCacheIfWarm() {
    guard !seeded, resolved == nil else { return }
    let trimmed = channelId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, let cached = runtime.apiClient.cachedResolve(channelId: trimmed) else { return }
    let mergedAttrs = mergeSdkAttributes(host: runtime.config.sdkAttributes, attribution: attributionSnapshot())
    var initial = initFlowState(
      manifest: cached.manifest,
      locale: runtime.config.locale,
      platform: runtime.config.platform.rawValue,
      sdkAttributes: mergedAttrs
    )
    initial = startFlow(initial) { [weak self] telemetry in
      Task { @MainActor in self?.enqueueDecisionEvaluated(telemetry) }
    }
    resolved = cached
    state = initial
    loading = false
    seeded = true
  }

  public func resolve() async {
    let trimmed = channelId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      error = RheoSDKError.channelRequired("useFlow: `channelId` is required.")
      loading = false
      return
    }

    // Warm seed: the flow is already rendering from cache. Emit flow_started
    // once and revalidate in the background without hot-swapping the live flow.
    if seeded, let data = resolved {
      seeded = false
      if !started {
        started = true
        enqueueSdk(.init(
          name: .flowStarted,
          flowId: data.flowId,
          versionId: data.versionId,
          experimentId: data.experimentId,
          variantId: data.variantId
        ))
      }
      startAttributionIfNeeded(data)
      emitViewedIfNeeded()
      presentExternalSurfaceIfNeeded()
      handleTerminalIfNeeded()
      Task { _ = try? await runtime.apiClient.resolve(channelId: trimmed) }
      return
    }

    loading = true
    error = nil
    do {
      let data = try await runtime.apiClient.resolve(channelId: trimmed)
      resolved = data
      let mergedAttrs = mergeSdkAttributes(host: runtime.config.sdkAttributes, attribution: attributionSnapshot())
      var initial = initFlowState(
        manifest: data.manifest,
        locale: runtime.config.locale,
        platform: runtime.config.platform.rawValue,
        sdkAttributes: mergedAttrs
      )
      initial = startFlow(initial) { [weak self] telemetry in
        Task { @MainActor in self?.enqueueDecisionEvaluated(telemetry) }
      }
      state = initial
      startAttributionIfNeeded(data)
      loading = false
      if !started {
        started = true
        enqueueSdk(.init(
          name: .flowStarted,
          flowId: data.flowId,
          versionId: data.versionId,
          experimentId: data.experimentId,
          variantId: data.variantId
        ))
      }
      emitViewedIfNeeded()
      presentExternalSurfaceIfNeeded()
      handleTerminalIfNeeded()
    } catch {
      resolved = nil
      state = nil
      self.error = error
      loading = false
    }
  }

  public func respond(_ response: StepResponse) {
    guard let previous = state, let data = resolved else { return }
    let previousScreenId = previous.currentScreenId
    let previousScreen = previousScreenId.flatMap { previous.manifest.screen(id: $0) }
    let analyticsSource: StepResponse
    let navKind: String
    if case .screenCommit(let primary, _, let capturedDraft) = response {
      analyticsSource = primary
      navKind = primary.kind
      if let capturedDraft, let draft = capturedDraft.eligibleConsumedDraft, let previousScreenId {
        enqueueInputAnalytics(
          data: data,
          previousScreenId: previousScreenId,
          screen: previousScreen,
          response: draft
        )
      }
    } else {
      analyticsSource = response
      navKind = response.kind
    }

    if case .goBack = response {
      let next = submitResponse(previous, response: response) { [weak self] telemetry in
        Task { @MainActor in self?.enqueueDecisionEvaluated(telemetry) }
      }
      guard next.currentScreenId != previous.currentScreenId else { return }
      state = next
      emitViewedIfNeeded()
      return
    }

    enqueueInputAnalytics(data: data, previousScreenId: previousScreenId, screen: previousScreen, response: analyticsSource)
    if case .permissionOutcome(_, let permissionKey, let outcome) = response, let previousScreenId {
      enqueueSdk(.init(
        name: .textSubmitted,
        flowId: data.flowId,
        versionId: data.versionId,
        experimentId: data.experimentId,
        variantId: data.variantId,
        stepId: previousScreenId,
        properties: ["field_key": .string(permissionCaptureFieldKey(permissionKey)), "value": .string(outcome.rawValue)],
        fieldClassification: "safe"
      ))
    }
    if case .screenCommit(let primary, _, _) = response,
       case .appReviewOutcome(let layerId, let outcome) = primary,
       let previousScreenId {
      enqueueSdk(.init(
        name: .textSubmitted,
        flowId: data.flowId,
        versionId: data.versionId,
        experimentId: data.experimentId,
        variantId: data.variantId,
        stepId: previousScreenId,
        properties: [
          "field_key": .string(appReviewCaptureFieldKey(layerId)),
          "value": .string(outcome.rawValue),
        ],
        fieldClassification: "safe"
      ))
    }

    let next = submitResponse(previous, response: response) { [weak self] telemetry in
      Task { @MainActor in self?.enqueueDecisionEvaluated(telemetry) }
    }
    state = next

    let oauthFailNoAdvance: Bool
    if case .oauthLoginResolve(_, _, let success, _, _) = response {
      oauthFailNoAdvance = !success
    } else {
      oauthFailNoAdvance = false
    }
    let leftRunningStep = previousScreenId != nil &&
      previous.status == .running &&
      !oauthFailNoAdvance &&
      (next.currentScreenId != previousScreenId || next.status == .completed)

    if case .skip = response, leftRunningStep {
      enqueueSdk(.init(
        name: .stepSkipped,
        flowId: data.flowId,
        versionId: data.versionId,
        experimentId: data.experimentId,
        variantId: data.variantId,
        stepId: previousScreenId
      ))
    }

    if next.status == .completed {
      enqueueSdk(.init(
        name: .flowCompleted,
        flowId: data.flowId,
        versionId: data.versionId,
        experimentId: data.experimentId,
        variantId: data.variantId,
        properties: ["responseCount": .number(Double(buildCompletionResponses(next).count))]
      ))
    } else if previousScreenId != nil && !oauthFailNoAdvance && response.kind != "skip" {
      enqueueSdk(.init(
        name: .stepCompleted,
        flowId: data.flowId,
        versionId: data.versionId,
        experimentId: data.experimentId,
        variantId: data.variantId,
        stepId: previousScreenId,
        properties: navKind == "go_to_screen" ? ["empty_capture": .bool(true)] : nil
      ))
    }

    emitViewedIfNeeded()
    presentExternalSurfaceIfNeeded()
    handleTerminalIfNeeded()
  }

  public func abandon() {
    guard let previous = state, previous.status == .running, let data = resolved else { return }
    enqueueSdk(.init(
      name: .flowAbandoned,
      flowId: data.flowId,
      versionId: data.versionId,
      experimentId: data.experimentId,
      variantId: data.variantId,
      stepId: previous.currentScreenId
    ))
    state = abandonFlow(previous)
    handleTerminalIfNeeded()
  }

  public func relayButtonAction(
    _ action: ButtonAction,
    layerId: String,
    appReviewCommit: AppReviewButtonCommit? = nil
  ) {
    if case .requestOSPermission(let permissionKey, _) = action {
      Task {
        let outcome = await OSPermissionRequester.request(permissionKey)
        await MainActor.run {
          self.respond(.permissionOutcome(layerId: layerId, permissionKey: permissionKey, outcome: outcome))
        }
      }
      return
    }

    guard case .requestAppReview = action else { return }
    let commit = appReviewCommit ?? AppReviewButtonCommit(checkboxValues: [:])
    let data = resolved
    let screenId = state?.currentScreenId

    Task {
      let result = await AppReviewRequester.requestIfAvailable()
      await MainActor.run {
        guard let data, let screenId else { return }
        if result == .shown {
          self.enqueueSdk(.init(
            name: .appReviewPromptShown,
            flowId: data.flowId,
            versionId: data.versionId,
            experimentId: data.experimentId,
            variantId: data.variantId,
            stepId: screenId,
            properties: ["layer_id": .string(layerId)]
          ))
          self.enqueueSdk(.init(
            name: .appReviewPromptDismissed,
            flowId: data.flowId,
            versionId: data.versionId,
            experimentId: data.experimentId,
            variantId: data.variantId,
            stepId: screenId,
            properties: ["layer_id": .string(layerId)]
          ))
        }
        let outcome: AppReviewOutcome = result == .shown ? .dismissed : .notShown
        self.respond(
          .screenCommit(
            primary: .appReviewOutcome(layerId: layerId, outcome: outcome),
            checkboxValues: commit.checkboxValues,
            capturedDraft: commit.capturedDraft
          )
        )
      }
    }
  }

  public func trackExternalLinkOpened(layerId: String, href: String) {
    guard let data = resolved, let screenId = state?.currentScreenId, let url = URL(string: href), let scheme = url.scheme else { return }
    var properties: [String: JSONValue] = [
      "layerId": .string(layerId),
      "hrefScheme": .string(scheme),
    ]
    if scheme == "https", let host = url.host {
      properties["linkHost"] = .string(host)
    }
    enqueueSdk(.init(
      name: .externalLinkOpened,
      flowId: data.flowId,
      versionId: data.versionId,
      experimentId: data.experimentId,
      variantId: data.variantId,
      stepId: screenId,
      properties: properties
    ))
  }

  private func enqueueInputAnalytics(data: SdkResolveResponse, previousScreenId: String?, screen: Screen?, response: StepResponse) {
    guard let previousScreenId, let screen else { return }
    switch response {
    case .choice(let choiceId):
      let fieldKey = findInputLayer(screen).map(inputFieldKey) ?? ""
      enqueueSdk(.init(name: .choiceSelected, flowId: data.flowId, versionId: data.versionId, experimentId: data.experimentId, variantId: data.variantId, stepId: previousScreenId, properties: ["field_key": .string(fieldKey), "value": .string(choiceId)]))
    case .multiChoice(let choiceIds):
      let fieldKey = findInputLayer(screen).map(inputFieldKey) ?? ""
      for choiceId in choiceIds {
        enqueueSdk(.init(name: .choiceSelected, flowId: data.flowId, versionId: data.versionId, experimentId: data.experimentId, variantId: data.variantId, stepId: previousScreenId, properties: ["field_key": .string(fieldKey), "value": .string(choiceId)]))
      }
    case .text(let value, let classification):
      let fieldKey = findInputLayer(screen).map(inputFieldKey) ?? ""
      enqueueSdk(.init(name: .textSubmitted, flowId: data.flowId, versionId: data.versionId, experimentId: data.experimentId, variantId: data.variantId, stepId: previousScreenId, properties: ["field_key": .string(fieldKey), "value": .string(value)], fieldClassification: classification))
    case .scale(let value):
      let fieldKey = findInputLayer(screen).map(inputFieldKey) ?? ""
      enqueueSdk(.init(name: .textSubmitted, flowId: data.flowId, versionId: data.versionId, experimentId: data.experimentId, variantId: data.variantId, stepId: previousScreenId, properties: ["field_key": .string(fieldKey), "value": .number(value)], fieldClassification: "safe"))
    default:
      break
    }
  }

  private func emitViewedIfNeeded() {
    guard let data = resolved, let screenId = state?.currentScreenId else { return }
    guard lastViewedScreenId != screenId else { return }
    lastViewedScreenId = screenId
    enqueueSdk(.init(
      name: .stepViewed,
      flowId: data.flowId,
      versionId: data.versionId,
      experimentId: data.experimentId,
      variantId: data.variantId,
      stepId: screenId
    ))
  }

  private func presentExternalSurfaceIfNeeded() {
    guard let data = resolved, let state, let pending = state.pendingExternalSurface else {
      presentedSurfaceId = nil
      return
    }
    guard presentedSurfaceId != pending.nodeId else { return }
    guard let node = state.manifest.externalSurface(id: pending.nodeId) else { return }
    presentedSurfaceId = pending.nodeId
    enqueueSdk(.init(
      name: .surfacePresented,
      flowId: data.flowId,
      versionId: data.versionId,
      experimentId: data.experimentId,
      variantId: data.variantId,
      stepId: pending.nodeId,
      properties: ["surface_node_id": .string(pending.nodeId), "provider": .string(node.config.provider)]
    ))
    Task {
      let result = await externalSurfacePresenter(node)
      await MainActor.run {
        self.enqueueSdk(.init(
          name: .surfaceOutcome,
          flowId: data.flowId,
          versionId: data.versionId,
          experimentId: data.experimentId,
          variantId: data.variantId,
          stepId: pending.nodeId,
          properties: ["surface_node_id": .string(pending.nodeId), "provider": .string(node.config.provider), "outcome": .string(result.outcome.rawValue)]
        ))
        if result.outcome == .purchaseCompleted, let commerce = result.commerce {
          self.enqueueIapPurchase(
            data: data,
            nodeId: pending.nodeId,
            provider: node.config.provider,
            commerce: commerce
          )
        }
        self.respond(.externalSurfaceOutcome(nodeId: pending.nodeId, outcome: result.outcome, sdkKeyPatch: result.sdkKeyPatch))
      }
    }
  }

  private func enqueueIapPurchase(
    data: SdkResolveResponse,
    nodeId: String,
    provider: String,
    commerce: RevenueCatPurchaseCommerce
  ) {
    var properties: [String: JSONValue] = [
      "provider": .string(provider),
      "surface_node_id": .string(nodeId),
      "product_id": .string(commerce.productId),
    ]
    if let offeringId = commerce.offeringId { properties["offering_id"] = .string(offeringId) }
    if let packageId = commerce.packageId { properties["package_id"] = .string(packageId) }
    if let periodType = commerce.periodType { properties["period_type"] = .string(periodType) }
    // Price + currency travel together — drop both if either is missing.
    if let price = commerce.price, let currency = commerce.currency {
      properties["price"] = .number(price)
      properties["currency"] = .string(currency.uppercased())
    }
    enqueueSdk(.init(
      name: .iapPurchase,
      flowId: data.flowId,
      versionId: data.versionId,
      experimentId: data.experimentId,
      variantId: data.variantId,
      stepId: nodeId,
      properties: properties
    ))
  }

  private func handleTerminalIfNeeded() {
    guard let state, let resolved else { return }
    guard state.status == .completed || state.status == .abandoned else { return }
    let key = "\(state.status.rawValue):\(state.completedAt ?? "")"
    guard terminalHandledKey != key else { return }
    terminalHandledKey = key
    let subject = SdkIdentity(
      appUserId: runtime.config.resolvedAppUserId(),
      customUserId: runtime.config.customUserId,
      sessionId: runtime.config.sessionId
    )
    let snapshot = buildTerminalSnapshot(
      terminal: state.status == .completed ? "completed" : "abandoned",
      resolved: resolved,
      state: state,
      subject: subject,
      appVersion: runtime.config.appVersion,
      customProperties: runtime.config.customProperties,
      includeManifest: includeManifestInTerminalPayload,
      includePath: includePathInTerminalPayload,
      includeAnswerDetail: includeAnswerDetailInTerminalPayload
    )
    if state.status == .completed {
      onFlowCompleted?(snapshot)
    } else {
      onFlowAbandoned?(snapshot)
    }
  }

  private func enqueueDecisionEvaluated(_ telemetry: DecisionEvaluationTelemetry) {
    guard let data = resolved else { return }
    enqueueSdk(.init(
      name: .decisionEvaluated,
      flowId: data.flowId,
      versionId: data.versionId,
      experimentId: data.experimentId,
      variantId: data.variantId,
      properties: [
        "decision_node_id": .string(telemetry.decisionNodeId),
        "matched_case_id": telemetry.matchedCaseId.map(JSONValue.string) ?? .null,
        "used_else_branch": .bool(telemetry.matchedCaseId == nil),
        "clause_digest": .array(telemetry.clauseDigest.map { .string($0) }),
      ]
    ))
  }

  private func enqueueSdk(_ input: TrackEventInput) {
    Task {
      await runtime.eventQueue.enqueue(input, channelId: channelId)
    }
  }

  private func attributionSnapshot() -> [String: JSONValue] {
    attributionRuntime?.currentAttributes() ?? [:]
  }

  private func startAttributionIfNeeded(_ data: SdkResolveResponse) {
    guard let attributionRuntime = attributionRuntime else { return }
    guard data.features?.attribution == true, data.integrations.appsflyer?.enabled == true else { return }
    attributionUnsubscribe?()
    attributionUnsubscribe = attributionRuntime.subscribe { [weak self] attrs in
      Task { @MainActor in
        self?.applyAttributionAttributes(attrs)
      }
    }
  }

  private func applyAttributionAttributes(_ attrs: [String: JSONValue]) {
    guard var current = state, !attrs.isEmpty else { return }
    let merged = mergeSdkAttributes(host: runtime.config.sdkAttributes, attribution: attrs)
    guard merged != current.session.sdkAttributes else { return }
    current.session.sdkAttributes = merged
    state = current
    if let data = resolved {
      enqueueSdk(.init(
        name: .attributionContextObserved,
        flowId: data.flowId,
        versionId: data.versionId,
        experimentId: data.experimentId,
        variantId: data.variantId,
        properties: ["keyCount": .number(Double(attrs.count))]
      ))
    }
  }
}

private func mergeSdkAttributes(
  host: [String: JSONValue],
  attribution: [String: JSONValue]
) -> [String: JSONValue] {
  var merged = host
  for (key, value) in attribution {
    merged[key] = value
  }
  return merged
}
