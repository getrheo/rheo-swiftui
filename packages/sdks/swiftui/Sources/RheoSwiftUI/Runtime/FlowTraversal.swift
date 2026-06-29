import Foundation

public func walkLayers(_ layer: Layer, _ visit: (Layer) -> Void) {
  visit(layer)
  for child in layer.children {
    walkLayers(child, visit)
  }
}

public func walkScreen(_ screen: Screen, _ visit: (Layer) -> Void) {
  if let header = screen.regions.header {
    walkLayers(.stack(header), visit)
  }
  walkLayers(.stack(screen.regions.body), visit)
  if let footer = screen.regions.footer {
    walkLayers(.stack(footer), visit)
  }
}

public func findLayerById(_ screen: Screen, _ id: String) -> Layer? {
  var found: Layer?
  walkScreen(screen) { layer in
    if layer.id == id {
      found = layer
    }
  }
  return found
}

public func findInputLayer(_ screen: Screen) -> Layer? {
  var found: Layer?
  walkScreen(screen) { layer in
    if found != nil { return }
    switch layer {
    case .singleChoice, .multipleChoice, .textInput, .scaleInput:
      found = layer
    default:
      break
    }
  }
  return found
}

public func screenHasContinueButton(_ screen: Screen) -> Bool {
  var has = false
  walkScreen(screen) { layer in
    if case .button(let button) = layer, button.action == .continue {
      has = true
    }
  }
  return has
}

public func findManualSubmitInputLayer(_ screen: Screen) -> Layer? {
  guard screenHasContinueButton(screen) else { return nil }
  return findInputLayer(screen)
}

public func findOptionStackForChoice(_ layer: Layer, optionId: String) -> StackLayer? {
  switch layer {
  case .singleChoice(let choice):
    guard let binding = choice.optionBindings.first(where: { $0.optionId == optionId }) else { return nil }
    for child in choice.children {
      if case .stack(let stack) = child, stack.id == binding.rootLayerId {
        return stack
      }
    }
  case .multipleChoice(let choice):
    guard let binding = choice.optionBindings.first(where: { $0.optionId == optionId }) else { return nil }
    for child in choice.children {
      if case .stack(let stack) = child, stack.id == binding.rootLayerId {
        return stack
      }
    }
  default:
    return nil
  }
  return nil
}

public func collectAnswerCaptureFieldKeys(from screen: Screen) -> [String] {
  var keys: [String] = []
  walkScreen(screen) { layer in
    switch layer {
    case .singleChoice(let layer):
      keys.append(layer.fieldKey)
    case .multipleChoice(let layer):
      keys.append(layer.fieldKey)
    case .textInput(let layer):
      keys.append(layer.fieldKey)
    case .scaleInput(let layer):
      keys.append(layer.fieldKey)
    case .checkbox(let layer):
      keys.append(layer.fieldKey)
    case .button(let layer):
      if case .requestOSPermission(let key, _) = layer.action {
        keys.append(permissionCaptureFieldKey(key))
      }
      if case .requestAppReview = layer.action {
        keys.append(appReviewCaptureFieldKey(layer.id))
      }
    default:
      break
    }
  }
  return keys
}

public func permissionCaptureFieldKey(_ key: OSPermissionKey) -> String {
  "permission:\(key)"
}

public func appReviewCaptureFieldKey(_ layerId: String) -> String {
  "app_review:\(layerId)"
}

public func oauthLoginResponseKey(_ layerId: String) -> String {
  "oauth:\(layerId)"
}

public func emailPasswordAuthResponseKey(_ layerId: String) -> String {
  "email_pw:\(layerId)"
}

public func externalSurfaceResponseKey(_ nodeId: String) -> String {
  "surface_\(nodeId)"
}
