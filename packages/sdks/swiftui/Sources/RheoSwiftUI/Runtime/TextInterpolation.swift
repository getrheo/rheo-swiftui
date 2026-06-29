import Foundation

public func resolveAndInterpolateLocalizedText(
  _ text: LocalizedText,
  manifest: FlowManifest,
  locale: String,
  responses: [String: StepResponse],
  customProperties: [String: String]
) -> String {
  let raw = text.resolve(locale: locale)
  return interpolateTemplate(raw, manifest: manifest, responses: responses, customProperties: customProperties)
}

public func interpolateTemplate(
  _ raw: String,
  manifest: FlowManifest,
  responses: [String: StepResponse],
  customProperties: [String: String]
) -> String {
  var out = raw
  let pattern = #"\{\{\s*([^}]+?)\s*\}\}"#
  guard let regex = try? NSRegularExpression(pattern: pattern) else { return raw }
  let ns = raw as NSString
  let matches = regex.matches(in: raw, range: NSRange(location: 0, length: ns.length)).reversed()
  for match in matches {
    guard match.numberOfRanges >= 2 else { continue }
    let token = ns.substring(with: match.range(at: 1))
    let replacement: String
    if token.hasPrefix("custom.") {
      let key = String(token.dropFirst("custom.".count))
      replacement = customProperties[key] ?? ""
    } else if let value = responses[token].flatMap(stepResponseToCompletionValue) {
      replacement = displayString(value)
    } else {
      replacement = ""
    }
    out = (out as NSString).replacingCharacters(in: match.range, with: replacement)
  }
  return out
}

private func displayString(_ value: JSONValue) -> String {
  switch value {
  case .string(let value): return value
  case .number(let value):
    return value.rounded() == value ? String(Int(value)) : String(value)
  case .bool(let value): return value ? "true" : "false"
  case .array(let values): return values.map(displayString).joined(separator: ", ")
  case .object, .null: return ""
  }
}
