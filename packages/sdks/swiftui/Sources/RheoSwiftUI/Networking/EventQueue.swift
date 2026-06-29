import Foundation

public actor EventQueue {
  private struct BufferedItem: Sendable {
    var channelId: String
    var input: TrackEventInput
  }

  private let configProvider: @Sendable () -> RheoConfig
  private var buffer: [BufferedItem] = []
  private var flushTask: Task<Void, Never>?
  private let maxBatchSize = 500
  private let flushNanoseconds: UInt64 = 5_000_000_000

  public init(configProvider: @escaping @Sendable () -> RheoConfig) {
    self.configProvider = configProvider
  }

  public func enqueue(_ input: TrackEventInput, channelId: String) {
    let trimmed = channelId.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      print("[rheo] enqueue skipped: missing channelId")
      return
    }
    buffer.append(BufferedItem(channelId: trimmed, input: input))
    if buffer.count >= maxBatchSize || input.name == .flowCompleted || input.name == .flowAbandoned {
      scheduleFlushNow()
      return
    }
    scheduleFlushSoon()
  }

  public func flush() async {
    flushTask?.cancel()
    flushTask = nil
    guard !buffer.isEmpty else { return }
    let drained = buffer
    buffer.removeAll()

    let grouped = Dictionary(grouping: drained, by: \.channelId)
    let config = configProvider()
    let client = RheoAPIClient(config: config)
    for (channelId, items) in grouped {
      let inputs = items.map(\.input)
      var start = 0
      while start < inputs.count {
        let end = min(start + maxBatchSize, inputs.count)
        let slice = Array(inputs[start..<end])
        let events = slice.map { buildSdkEvent(config: config, input: $0) }
        await client.send(events: events, channelId: channelId)
        start = end
      }
    }
    if !buffer.isEmpty {
      await flush()
    }
  }

  public func shutdown() async {
    await flush()
  }

  private func scheduleFlushSoon() {
    guard flushTask == nil else { return }
    flushTask = Task { [weak self] in
      try? await Task.sleep(nanoseconds: flushNanoseconds)
      await self?.flush()
    }
  }

  private func scheduleFlushNow() {
    flushTask?.cancel()
    flushTask = Task { [weak self] in
      await self?.flush()
    }
  }
}

public func buildSdkEvent(config: RheoConfig, input: TrackEventInput) -> SdkEvent {
  let custom = config.customProperties.mapValues { JSONValue.string($0) }
  return SdkEvent(
    eventId: UUID().uuidString.lowercased(),
    name: input.name,
    timestamp: input.timestamp ?? ISO8601DateFormatter.rheo.string(from: Date()),
    flowId: input.flowId,
    versionId: input.versionId,
    experimentId: input.experimentId,
    variantId: input.variantId,
    stepId: input.stepId,
    identity: SdkIdentity(
      appUserId: config.resolvedAppUserId(),
      customUserId: config.customUserId,
      sessionId: config.sessionId
    ),
    context: SdkContext(
      platform: config.platform,
      appVersion: config.appVersion,
      locale: config.locale,
      customProperties: custom.isEmpty ? nil : custom
    ),
    properties: input.properties,
    fieldClassification: input.fieldClassification
  )
}
