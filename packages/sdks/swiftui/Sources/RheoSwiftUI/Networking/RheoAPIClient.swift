import Foundation

/// Dedupes concurrent resolves for the same cache key so a provider prefetch and
/// a `FlowView` mounting at the same moment share one network request + cache write.
private actor InFlightResolves {
  private var tasks: [String: Task<SdkResolveResponse, Error>] = [:]

  func resolve(
    key: String,
    perform: @Sendable @escaping () async throws -> SdkResolveResponse
  ) async throws -> SdkResolveResponse {
    if let existing = tasks[key] {
      return try await existing.value
    }
    let task = Task { try await perform() }
    tasks[key] = task
    defer { tasks[key] = nil }
    return try await task.value
  }
}

public final class RheoAPIClient: @unchecked Sendable {
  private let config: RheoConfig
  private let manifestCache: ManifestResolveCache
  private let inFlight = InFlightResolves()

  public init(config: RheoConfig, manifestCache: ManifestResolveCache = ManifestResolveCache()) {
    self.config = config
    self.manifestCache = manifestCache
  }

  private func cacheKey(for channelId: String) -> String {
    manifestCache.cacheKey(
      apiBaseURL: config.apiBaseURL,
      publishableKey: config.publishableKey,
      channelId: channelId,
      locale: config.locale
    )
  }

  /// Synchronous read of a prefetched manifest from the cache (memory, then disk).
  /// Used by `FlowController` to seed a warm mount without a network round-trip.
  public func cachedResolve(channelId: String) -> SdkResolveResponse? {
    let trimmed = channelId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    return manifestCache.load(key: cacheKey(for: trimmed))?.body
  }

  public func resolve(channelId: String) async throws -> SdkResolveResponse {
    let trimmed = channelId.trimmingCharacters(in: .whitespacesAndNewlines)
    let key = cacheKey(for: trimmed)
    return try await inFlight.resolve(key: key) { [self] in
      try await performResolve(channelId: trimmed, cacheKey: key)
    }
  }

  private func performResolve(channelId trimmed: String, cacheKey: String) async throws -> SdkResolveResponse {
    let cached = manifestCache.load(key: cacheKey)
    let ifNoneMatch = ManifestResolveCache.shouldSendConditional(cached) ? cached?.etag : nil
    let request = try URLRequestFactory.resolveRequest(
      config: config,
      channelId: trimmed,
      ifNoneMatch: ifNoneMatch
    )
    let (data, response) = try await config.urlSession.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw RheoSDKError.requestFailed(statusCode: -1, message: "invalid response")
    }

    if http.statusCode == 304 {
      guard let cached else {
        throw RheoSDKError.requestFailed(
          statusCode: 304,
          message: "resolve returned 304 without a local manifest cache entry"
        )
      }
      return cached.body
    }

    guard (200..<300).contains(http.statusCode) else {
      throw mapSDKHTTPError(statusCode: http.statusCode, data: data)
    }

    let resolved = try JSONDecoder.rheo.decode(SdkResolveResponse.self, from: data)
    if let etag = http.value(forHTTPHeaderField: "ETag")?.trimmingCharacters(in: .whitespacesAndNewlines),
       !etag.isEmpty {
      manifestCache.save(
        key: cacheKey,
        entry: ManifestResolveCacheEntry(
          etag: etag,
          body: resolved,
          cachedAt: Date().timeIntervalSince1970
        )
      )
    }
    return resolved
  }

  /// Batch-prefetch every assigned channel (`POST /v1/sdk/resolve-all`) and
  /// write each entry through to the manifest cache. The per-channel ETag is
  /// reconstructed as `"{assignmentVersion}-{versionId}"` so later single resolves
  /// can revalidate with `If-None-Match`.
  @discardableResult
  public func resolveAll() async throws -> [SdkResolveResponse] {
    let request = try URLRequestFactory.resolveAllRequest(config: config)
    let (data, response) = try await config.urlSession.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw RheoSDKError.requestFailed(statusCode: -1, message: "invalid response")
    }
    guard (200..<300).contains(http.statusCode) else {
      throw mapSDKHTTPError(statusCode: http.statusCode, data: data)
    }
    let decoded = try JSONDecoder.rheo.decode(SdkResolveAllResponse.self, from: data)
    let cachedAt = Date().timeIntervalSince1970
    for entry in decoded.channels {
      manifestCache.save(
        key: cacheKey(for: entry.channelId),
        entry: ManifestResolveCacheEntry(
          etag: "\"\(entry.assignmentVersion)-\(entry.versionId)\"",
          body: entry,
          cachedAt: cachedAt
        )
      )
    }
    return decoded.channels
  }

  public func send(events: [SdkEvent], channelId: String) async {
    guard !events.isEmpty else { return }
    do {
      let request = try URLRequestFactory.eventsRequest(
        config: config,
        channelId: channelId,
        events: events
      )
      let (_, response) = try await config.urlSession.data(for: request)
      if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
        print("[rheo] events POST failed: \(http.statusCode)")
      }
    } catch {
      print("[rheo] events POST error: \(error)")
    }
  }
}

extension JSONDecoder {
  static let rheo: JSONDecoder = {
    let decoder = JSONDecoder()
    return decoder
  }()
}

extension JSONEncoder {
  static let rheo: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.withoutEscapingSlashes]
    return encoder
  }()
}
