import Foundation
import RheoSwiftUI

/// Host-installed RevenueCat bridge. Add `RevenueCat` and `RevenueCatUI` to the app target,
/// then pass a presenter that maps Rheo `revenuecat` surfaces to your paywall UI.
public enum RheoRevenueCatIntegration {
  public typealias PresentPaywall = @Sendable (
    RevenueCatSurfaceConfig,
    ExternalSurfaceNode
  ) async -> ExternalSurfaceResult

  public static func externalSurfacePresenter(
    presentPaywall: @escaping PresentPaywall
  ) -> ExternalSurfacePresenter {
    { node in
      guard case .revenueCat(let config) = node.config else {
        return ExternalSurfaceResult(outcome: .failed)
      }
      return await presentPaywall(config, node)
    }
  }

  /// Normalizes common RevenueCat paywall result strings to Rheo outcomes.
  ///
  /// On `PURCHASED`, pass `commerce` so the SDK can emit a fully populated
  /// `iap_purchase` analytics event. Read `productIdentifier`, the matching
  /// `StoreProduct` price/currency, and (optionally) `periodType` from your
  /// host RevenueCat callbacks (`onPurchaseCompleted`, `Purchases.getCustomerInfo`).
  public static func normalizePaywallResult(
    _ raw: String,
    commerce: RevenueCatPurchaseCommerce? = nil
  ) -> ExternalSurfaceResult {
    switch raw.uppercased() {
    case "PURCHASED":
      var keyPatch: [String: JSONValue] = ["onb_rc_last_event": .string("purchase_completed")]
      if let productId = commerce?.productId {
        keyPatch["onb_rc_last_product_id"] = .string(productId)
      }
      if let periodType = commerce?.periodType {
        keyPatch["onb_rc_last_period_type"] = .string(periodType)
      }
      if let offeringId = commerce?.offeringId {
        keyPatch["onb_rc_last_offering_id"] = .string(offeringId)
      }
      return ExternalSurfaceResult(
        outcome: .purchaseCompleted,
        sdkKeyPatch: keyPatch,
        commerce: commerce
      )
    case "RESTORED":
      return ExternalSurfaceResult(
        outcome: .restoreCompleted,
        sdkKeyPatch: ["onb_rc_last_event": .string("restore_completed")]
      )
    case "CANCELLED", "CANCELED":
      return ExternalSurfaceResult(outcome: .purchaseCancelled)
    default:
      return ExternalSurfaceResult(outcome: .failed)
    }
  }
}
