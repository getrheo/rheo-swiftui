import Foundation
import RheoSwiftUI

enum AppsFlyerLibAutomaticBridge {
  static func start(
    _ listener: @escaping @Sendable (NormalizedAttributionSnapshot?) -> Void
  ) -> @Sendable () -> Void {
    #if canImport(AppsFlyerLib)
    return AppsFlyerLibAutomaticBridgeImpl.shared.start(listener)
    #else
    _ = listener
    return {}
    #endif
  }
}

#if canImport(AppsFlyerLib)
import AppsFlyerLib

private final class AppsFlyerLibAutomaticBridgeImpl: NSObject, AppsFlyerLibDelegate, DeepLinkDelegate, @unchecked Sendable {
  static let shared = AppsFlyerLibAutomaticBridgeImpl()

  private let lock = NSLock()
  private var listener: (@Sendable (NormalizedAttributionSnapshot?) -> Void)?
  private var facets: AppsFlyerAttributionFacets?

  func start(
    _ listener: @escaping @Sendable (NormalizedAttributionSnapshot?) -> Void
  ) -> @Sendable () -> Void {
    lock.lock()
    self.listener = listener
    lock.unlock()

    let lib = AppsFlyerLib.shared()
    lib.delegate = self
    lib.deepLinkDelegate = self

    emitCurrentSnapshot()

    return { [weak self] in
      self?.stop()
    }
  }

  private func stop() {
    lock.lock()
    listener = nil
    facets = nil
    lock.unlock()
    let lib = AppsFlyerLib.shared()
    if lib.delegate === self {
      lib.delegate = nil
    }
    if lib.deepLinkDelegate === self {
      lib.deepLinkDelegate = nil
    }
  }

  func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
    let overlay = AppsFlyerPayloadNormalizer.normalizeConversionPayload(
      root: AppsFlyerDictionaryHelpers.stringKeyed(conversionInfo)
    )
    emitMerged(overlay: overlay)
  }

  func onConversionDataFail(_ error: Error) {
    _ = error
  }

  func didResolveDeepLink(_ result: DeepLinkResult) {
    guard result.status == .found, let deepLink = result.deepLink else { return }
    let overlay = AppsFlyerPayloadNormalizer.normalizeDeepLinkPayload(
      root: Self.deepLinkPayload(deepLink)
    )
    emitMerged(overlay: overlay)
  }

  private func emitMerged(overlay: AppsFlyerAttributionFacets) {
    lock.lock()
    facets = AppsFlyerPayloadNormalizer.mergeFacets(base: facets, overlay: overlay)
    let merged = facets
    let listener = listener
    lock.unlock()

    guard let merged, let listener else { return }
    let snap = AppsFlyerPayloadNormalizer.flatten(merged)
    guard AppsFlyerPayloadNormalizer.snapshotHasSignal(snap) else { return }
    listener(snap)
  }

  private func emitCurrentSnapshot() {
    lock.lock()
    let merged = facets
    let listener = listener
    lock.unlock()
    guard let merged, let listener else { return }
    let snap = AppsFlyerPayloadNormalizer.flatten(merged)
    guard AppsFlyerPayloadNormalizer.snapshotHasSignal(snap) else { return }
    listener(snap)
  }

  private static func deepLinkPayload(_ deepLink: DeepLink) -> [String: Any] {
    var root: [String: Any] = [:]
    if let clickEvent = deepLink.clickEvent as? [AnyHashable: Any] {
      root["click_event"] = AppsFlyerDictionaryHelpers.stringKeyed(clickEvent)
    } else if let clickEvent = deepLink.clickEvent as? [String: Any] {
      root["click_event"] = clickEvent
    }
    if let value = deepLink.deeplinkValue, !value.isEmpty {
      root["deep_link_value"] = value
    }
    if let campaign = deepLink.campaign, !campaign.isEmpty {
      root["campaign"] = campaign
    }
    if let mediaSource = deepLink.mediaSource, !mediaSource.isEmpty {
      root["media_source"] = mediaSource
    }
    if let matchType = deepLink.matchType, !matchType.isEmpty {
      root["match_type"] = matchType
    }
    return root
  }
}
#endif
