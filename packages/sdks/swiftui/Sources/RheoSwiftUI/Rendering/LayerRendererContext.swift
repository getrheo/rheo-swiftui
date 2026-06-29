import SwiftUI

enum RegionKind {
  case header
  case body
  case footer
}

struct LayerRendererContext {
  var manifest: FlowManifest
  var screen: Screen
  var locale: String
  var interactive: Bool
  var mediaMap: [String: URL]
  var theme: ThemeMode
  var isRegionRoot: Bool
  var regionKind: RegionKind?
  var regionHeight: CGFloat?
  var interpolationContext: InterpolationContext?
  var branding: Branding?
  var previewWidthPx: Double
  var onRespond: (StepResponse) -> Void
  var onAction: (ButtonAction, String, AppReviewButtonCommit?) -> Void
  var onHyperlinkOpened: (String, String) -> Void
  var oauthLoginHandler: OAuthLoginHandler?
  var emailPasswordAuthHandler: EmailPasswordAuthHandler?
}

public struct InterpolationContext: Sendable {
  public var responses: [String: StepResponse]
  public var customProperties: [String: String]
  public var canGoBack: Bool
}

final class ScreenInputDraftStore: ObservableObject {
  @Published var draft: InputDraft?
  let screen: Screen

  init(screen: Screen) {
    self.screen = screen
    if case .scaleInput(let layer)? = findInputLayer(screen) {
      self.draft = .scale(snapScaleValue(layer, layer.defaultValue ?? layer.min))
    } else {
      self.draft = nil
    }
  }

  var validity: Bool {
    guard let input = findInputLayer(screen) else { return true }
    guard let draft else { return false }
    switch (input, draft) {
    case (.textInput(let layer), .text(let value)):
      return validateTextInputValue(layer, value) == .ok
    case (.scaleInput(let layer), .scale(let value)):
      return scaleValueInRange(layer, value) && scaleValueIsOnStep(layer, value)
    case (.multipleChoice(let layer), .multiChoice(let ids)):
      let min = layer.minSelections ?? 1
      if ids.count < min { return false }
      if let max = layer.maxSelections, ids.count > max { return false }
      return true
    case (.singleChoice, .choice):
      return true
    default:
      return false
    }
  }

  func toResponse() -> StepResponse? {
    guard let draft, let input = findInputLayer(screen) else { return nil }
    switch draft {
    case .choice(let id):
      return .choice(choiceId: id)
    case .multiChoice(let ids):
      return .multiChoice(choiceIds: ids)
    case .text(let value):
      if case .textInput(let layer) = input {
        return .text(value: value, classification: layer.classification)
      }
      return nil
    case .scale(let value):
      return .scale(value: value)
    }
  }
}

enum InputDraft: Equatable {
  case choice(String)
  case multiChoice([String])
  case text(String)
  case scale(Double)
}

final class CheckboxAckStore: ObservableObject {
  @Published var checked: [String: Bool]
  private let screen: Screen

  init(screen: Screen) {
    self.screen = screen
    var initial: [String: Bool] = [:]
    walkScreen(screen) { layer in
      if case .checkbox(let checkbox) = layer {
        initial[checkbox.fieldKey] = false
      }
    }
    checked = initial
  }

  func toggle(_ fieldKey: String) {
    checked[fieldKey] = !(checked[fieldKey] ?? false)
  }

  var blockingContinue: Bool {
    var blocked = false
    walkScreen(screen) { layer in
      if case .checkbox(let checkbox) = layer, checkbox.blocking == true, checked[checkbox.fieldKey] != true {
        blocked = true
      }
    }
    return blocked
  }

  func snapshotValues() -> [String: Bool] {
    var out: [String: Bool] = [:]
    walkScreen(screen) { layer in
      if case .checkbox(let checkbox) = layer {
        out[checkbox.fieldKey] = checked[checkbox.fieldKey] ?? false
      }
    }
    return out
  }
}
