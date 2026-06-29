import Foundation

public struct NormalizedAttributionSnapshot: Sendable, Equatable {
  public var providerId: String
  public var capturedAtMs: Int64
  public var sdkAttributes: [String: JSONValue]

  public init(providerId: String, capturedAtMs: Int64, sdkAttributes: [String: JSONValue]) {
    self.providerId = providerId
    self.capturedAtMs = capturedAtMs
    self.sdkAttributes = sdkAttributes
  }
}

public protocol AttributionProvider: Sendable {
  func start(_ listener: @escaping @Sendable (NormalizedAttributionSnapshot?) -> Void) -> @Sendable () -> Void
}

public final class AttributionRuntime: @unchecked Sendable {
  private var providers: [AttributionProvider]
  private var unsubscribe: [@Sendable () -> Void] = []
  private var latest: [String: JSONValue] = [:]
  private let lock = NSLock()

  public init(providers: [AttributionProvider] = []) {
    self.providers = providers
  }

  public func currentAttributes() -> [String: JSONValue] {
    lock.lock()
    defer { lock.unlock() }
    return latest
  }

  public func subscribe(_ listener: @escaping @Sendable ([String: JSONValue]) -> Void) -> @Sendable () -> Void {
    for provider in providers {
      unsubscribe.append(
        provider.start { [weak self] snapshot in
          guard let self, let snapshot else { return }
          self.lock.lock()
          self.latest.merge(snapshot.sdkAttributes) { _, new in new }
          let next = self.latest
          self.lock.unlock()
          listener(next)
        }
      )
    }
    lock.lock()
    let current = latest
    lock.unlock()
    listener(current)
    return { [weak self] in
      guard let self else { return }
      self.unsubscribe.forEach { $0() }
      self.unsubscribe.removeAll()
    }
  }
}
