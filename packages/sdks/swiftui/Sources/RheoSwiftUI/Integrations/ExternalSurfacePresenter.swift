import Foundation

public typealias ExternalSurfacePresenter = @Sendable (ExternalSurfaceNode) async -> ExternalSurfaceResult

public let defaultExternalSurfacePresenter: ExternalSurfacePresenter = { node in
  switch node.config {
  case .revenueCat:
    return ExternalSurfaceResult(outcome: .failed, sdkKeyPatch: ["onb_rc_last_event": .string("failed")])
  case .unspecified:
    return ExternalSurfaceResult(outcome: .failed, sdkKeyPatch: ["onb_rc_last_event": .string("failed")])
  case .unknown:
    return ExternalSurfaceResult(outcome: .failed, sdkKeyPatch: ["onb_rc_last_event": .string("failed")])
  }
}
