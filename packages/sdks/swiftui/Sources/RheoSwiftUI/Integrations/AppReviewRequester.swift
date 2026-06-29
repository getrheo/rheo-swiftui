import Foundation
import StoreKit
import UIKit

public enum AppReviewRequester {
  public static let postPromptDelayNanoseconds: UInt64 = 1_500_000_000

  public enum RequestResult: Sendable {
    case notShown
    case shown
  }

  public static func requestIfAvailable() async -> RequestResult {
    guard await hasAction() else { return .notShown }
    await requestReview()
    try? await Task.sleep(nanoseconds: postPromptDelayNanoseconds)
    return .shown
  }

  public static func hasAction() async -> Bool {
    if #available(iOS 16.0, *) {
      return true
    }
    return false
  }

  @MainActor
  private static func requestReview() async {
    if #available(iOS 17.0, *) {
      guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
        return
      }
      AppStore.requestReview(in: scene)
    } else if #available(iOS 16.0, *) {
      guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
        return
      }
      SKStoreReviewController.requestReview(in: scene)
    }
  }
}
