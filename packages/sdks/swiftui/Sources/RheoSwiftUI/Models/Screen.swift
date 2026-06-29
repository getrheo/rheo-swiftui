import Foundation

public struct ScreenNext: Codable, Equatable, Sendable {
  public var `default`: FlowJumpTarget
}

public struct ScreenRegions: Codable, Equatable, Sendable {
  public var header: StackLayer?
  public var body: StackLayer
  public var footer: StackLayer?
}

public struct ScreenContainerStyle: Codable, Equatable, Sendable {
  public var padding: Padding?
  public var margin: Padding?
  public var insetSafeArea: Bool?
  public var backgroundFill: ScreenBackgroundFill?
}

extension ScreenContainerStyle {
  public var asCommonStyle: CommonStyle {
    var style = CommonStyle()
    style.padding = padding
    style.margin = margin
    return style
  }
}
public struct Screen: Codable, Equatable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var regions: ScreenRegions
  public var next: ScreenNext
  public var animations: [AnimationClip]?
  public var stagger: ScreenStagger?
  public var containerStyle: ScreenContainerStyle?
  public var containerStyleBreakpoints: ScreenContainerStyleBreakpoints?
}

extension Screen {
  public var allLayers: [Layer] {
    var layers: [Layer] = []
    func visit(_ layer: Layer) {
      layers.append(layer)
      for child in layer.children {
        visit(child)
      }
    }
    if let header = regions.header {
      visit(.stack(header))
    }
    visit(.stack(regions.body))
    if let footer = regions.footer {
      visit(.stack(footer))
    }
    return layers
  }
}
