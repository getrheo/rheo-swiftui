import Foundation

public func scaleStep(_ layer: ScaleInputLayer) -> Double {
  layer.step ?? 1
}

public func scaleValueInRange(_ layer: ScaleInputLayer, _ value: Double) -> Bool {
  value >= layer.min && value <= layer.max
}

public func scaleValueIsOnStep(_ layer: ScaleInputLayer, _ value: Double) -> Bool {
  let step = scaleStep(layer)
  if step <= 0 { return true }
  let offset = (value - layer.min) / step
  return abs(offset.rounded() - offset) < 0.000001
}

public func snapScaleValue(_ layer: ScaleInputLayer, _ value: Double) -> Double {
  let step = scaleStep(layer)
  if step <= 0 { return min(max(value, layer.min), layer.max) }
  let snapped = layer.min + ((value - layer.min) / step).rounded() * step
  return min(max(snapped, layer.min), layer.max)
}

public enum TextInputValidationResult: Equatable, Sendable {
  case ok
  case invalid(String)
}

public func validateTextInputValue(_ layer: TextInputLayer, _ value: String) -> TextInputValidationResult {
  let required = layer.required != false
  let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
  if required && trimmed.isEmpty {
    return .invalid("Required")
  }
  if let minLength = layer.minLength, value.count < minLength {
    return .invalid("Too short")
  }
  if let maxLength = layer.maxLength, value.count > maxLength {
    return .invalid("Too long")
  }
  if layer.inputType == "email", !trimmed.isEmpty, !trimmed.contains("@") {
    return .invalid("Enter a valid email")
  }
  if layer.inputType == "url", !trimmed.isEmpty, URL(string: trimmed)?.scheme == nil {
    return .invalid("Enter a valid URL")
  }
  return .ok
}

public enum EmailPasswordValidationResult: Equatable, Sendable {
  case ok
  case invalid(String)
}

public func validateEmailPasswordAuthFields(
  mode: EmailPasswordAuthMode,
  email: String,
  password: String,
  confirmPassword: String,
  minPasswordLength: Int = 8
) -> EmailPasswordValidationResult {
  let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
  if trimmedEmail.isEmpty || !trimmedEmail.contains("@") {
    return .invalid("Enter a valid email.")
  }
  if password.count < minPasswordLength {
    return .invalid("Password must be at least \(minPasswordLength) characters.")
  }
  if mode == .signUp && password != confirmPassword {
    return .invalid("Passwords do not match.")
  }
  return .ok
}
