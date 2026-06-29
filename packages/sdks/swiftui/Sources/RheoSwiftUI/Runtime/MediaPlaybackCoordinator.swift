import Foundation

@MainActor
public final class MediaPlaybackCoordinator: ObservableObject {
  private var players: [String: () -> Void] = [:]
  @Published public private(set) var playGeneration: Int = 0

  public init() {}

  public func register(layerId: String, play: @escaping () -> Void) {
    players[layerId] = play
  }

  public func unregister(layerId: String) {
    players.removeValue(forKey: layerId)
  }

  public func playMedia(layerIds: [String]) {
    for id in layerIds {
      players[id]?()
    }
    playGeneration += 1
  }
}

public func mediaAutoPlayOnMount(autoPlay: Bool?) -> Bool {
  autoPlay != false
}
