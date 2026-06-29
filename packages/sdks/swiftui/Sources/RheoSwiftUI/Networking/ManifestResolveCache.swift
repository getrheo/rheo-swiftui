import Foundation

public struct ManifestResolveCacheEntry: Codable, Sendable {
  public let etag: String
  public let body: SdkResolveResponse
  public let cachedAt: TimeInterval

  public init(etag: String, body: SdkResolveResponse, cachedAt: TimeInterval) {
    self.etag = etag
    self.body = body
    self.cachedAt = cachedAt
  }
}

public final class ManifestResolveCache: @unchecked Sendable {
  private let defaults: UserDefaults
  private let lock = NSLock()
  private var memory: [String: ManifestResolveCacheEntry] = [:]

  public init(userDefaults: UserDefaults = .standard) {
    self.defaults = userDefaults
  }

  public static let keyPrefix = "rheo:resolve:"

  public struct Summary: Sendable, Equatable {
    public let key: String
    public let apiBaseURL: String
    public let publishableKey: String
    public let channelId: String
    public let locale: String
    public let etag: String
    public let flowId: String
    public let versionId: String
    public let cachedAt: TimeInterval
    public let inMemory: Bool
  }

  public static func parseCacheKey(_ key: String) -> (apiBaseURL: String, publishableKey: String, channelId: String, locale: String)? {
    guard key.hasPrefix(keyPrefix) else { return nil }
    let rest = String(key.dropFirst(keyPrefix.count))
    let parts = rest.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
    guard parts.count >= 4 else { return nil }
    let locale = parts[parts.count - 1]
    let channelId = parts[parts.count - 2]
    let publishableKey = parts[parts.count - 3]
    let apiBaseURL = parts.dropLast(3).joined(separator: ":")
    guard !apiBaseURL.isEmpty, !publishableKey.isEmpty, !channelId.isEmpty else { return nil }
    return (apiBaseURL, publishableKey, channelId, locale)
  }

  public func listEntries() -> [Summary] {
    lock.lock()
    let memoryKeys = Set(memory.keys)
    lock.unlock()

    var keys = memoryKeys
    for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(Self.keyPrefix) {
      keys.insert(key)
    }

    var summaries: [Summary] = []
    for key in keys {
      let inMemory = memoryKeys.contains(key)
      guard let entry = load(key: key),
            let parsed = Self.parseCacheKey(key) else { continue }
      summaries.append(
        Summary(
          key: key,
          apiBaseURL: parsed.apiBaseURL,
          publishableKey: parsed.publishableKey,
          channelId: parsed.channelId,
          locale: parsed.locale,
          etag: entry.etag,
          flowId: entry.body.flowId,
          versionId: entry.body.versionId,
          cachedAt: entry.cachedAt,
          inMemory: inMemory
        )
      )
    }
    return summaries.sorted { $0.cachedAt > $1.cachedAt }
  }

  @discardableResult
  public func clearAll() -> Int {
    lock.lock()
    let memoryKeys = Array(memory.keys)
    memory.removeAll()
    lock.unlock()

    var keys = Set(memoryKeys)
    for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(Self.keyPrefix) {
      keys.insert(key)
    }
    for key in keys {
      defaults.removeObject(forKey: key)
    }
    return keys.count
  }

  public func cacheKey(apiBaseURL: URL, publishableKey: String, channelId: String, locale: String = "") -> String {
    let base = apiBaseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    let channel = channelId.trimmingCharacters(in: .whitespacesAndNewlines)
    let loc = locale.trimmingCharacters(in: .whitespacesAndNewlines)
    return "rheo:resolve:\(base):\(publishableKey):\(channel):\(loc)"
  }

  public func load(key: String) -> ManifestResolveCacheEntry? {
    lock.lock()
    if let mem = memory[key] {
      lock.unlock()
      return mem
    }
    lock.unlock()
    guard let data = defaults.data(forKey: key),
          let entry = try? JSONDecoder.rheo.decode(ManifestResolveCacheEntry.self, from: data),
          !entry.etag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return nil
    }
    lock.lock()
    memory[key] = entry
    lock.unlock()
    return entry
  }

  public func save(key: String, entry: ManifestResolveCacheEntry) {
    lock.lock()
    memory[key] = entry
    lock.unlock()
    if let data = try? JSONEncoder.rheo.encode(entry) {
      defaults.set(data, forKey: key)
    }
  }

  public static func shouldSendConditional(_ entry: ManifestResolveCacheEntry?) -> Bool {
    guard let entry else { return false }
    return !entry.etag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
