import Foundation

/// What `RheoProvider(prefetch:)` warms on mount.
public enum RheoPrefetch: Sendable {
  /// Batch-prefetch every assigned channel for the app via `POST /v1/sdk/resolve-all`.
  case all
  /// Prefetch only the given channel public ids (one resolve each).
  case channels([String])
}

/// Holds the active provider's API client so the standalone `Rheo.prefetch` /
/// `Rheo.prefetchAll` work from anywhere (e.g. before pushing a screen).
/// `RheoProvider` registers it on appear.
final class PrefetchRegistry: @unchecked Sendable {
  static let shared = PrefetchRegistry()
  private let lock = NSLock()
  private var apiClient: RheoAPIClient?

  func register(_ client: RheoAPIClient?) {
    lock.lock()
    apiClient = client
    lock.unlock()
  }

  private func current() -> RheoAPIClient? {
    lock.lock()
    defer { lock.unlock() }
    return apiClient
  }

  func prefetch(channelId: String) {
    guard let client = current() else { return }
    Task { _ = try? await client.resolve(channelId: channelId) }
  }

  func prefetchAll() {
    guard let client = current() else { return }
    Task { try? await client.resolveAll() }
  }
}

public extension Rheo {
  /// Imperatively warm the manifest cache for a channel. Best-effort and silent;
  /// no-ops until a `RheoProvider` has mounted.
  static func prefetch(channelId: String) {
    PrefetchRegistry.shared.prefetch(channelId: channelId)
  }

  /// Imperatively warm the manifest cache for every assigned channel in the app.
  static func prefetchAll() {
    PrefetchRegistry.shared.prefetchAll()
  }
}
