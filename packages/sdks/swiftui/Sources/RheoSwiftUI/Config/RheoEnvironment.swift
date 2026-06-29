import SwiftUI

public final class RheoRuntime: ObservableObject {
  @Published public private(set) var config: RheoConfig
  public let apiClient: RheoAPIClient
  public lazy var eventQueue: EventQueue = {
    let initialConfig = config
    return EventQueue(configProvider: { [weak self] in
      self?.config ?? initialConfig
    })
  }()

  public init(config: RheoConfig) {
    self.config = config
    self.apiClient = RheoAPIClient(config: config)
  }

  public func setCustomUserId(_ next: String?) {
    config.customUserId = next
  }
}

private struct RheoRuntimeKey: EnvironmentKey {
  static let defaultValue: RheoRuntime? = nil
}

extension EnvironmentValues {
  public var rheoRuntime: RheoRuntime? {
    get { self[RheoRuntimeKey.self] }
    set { self[RheoRuntimeKey.self] = newValue }
  }
}

public struct RheoProvider<Content: View>: View {
  @StateObject private var runtime: RheoRuntime
  private let content: Content
  private let prefetch: RheoPrefetch?

  public init(
    config: RheoConfig,
    prefetch: RheoPrefetch? = nil,
    @ViewBuilder content: () -> Content
  ) {
    _runtime = StateObject(wrappedValue: RheoRuntime(config: config))
    self.content = content()
    self.prefetch = prefetch
    RheoIconFontRegistration.registerBundledFonts()
  }

  public var body: some View {
    content
      .environment(\.rheoRuntime, runtime)
      .task {
        // Register for standalone Rheo.prefetch/prefetchAll, then run any
        // declared prefetch on mount. Best-effort and silent — a mounted
        // FlowView still owns error/retry UI.
        PrefetchRegistry.shared.register(runtime.apiClient)
        switch prefetch {
        case .all:
          try? await runtime.apiClient.resolveAll()
        case .channels(let ids):
          for id in ids {
            _ = try? await runtime.apiClient.resolve(channelId: id)
          }
        case .none:
          break
        }
      }
  }
}
