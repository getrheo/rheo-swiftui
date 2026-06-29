import Foundation

public struct AppReviewButtonCommit: Sendable {
  public var checkboxValues: [String: Bool]
  public var capturedDraft: StepResponse?

  public init(checkboxValues: [String: Bool], capturedDraft: StepResponse? = nil) {
    self.checkboxValues = checkboxValues
    self.capturedDraft = capturedDraft
  }
}
