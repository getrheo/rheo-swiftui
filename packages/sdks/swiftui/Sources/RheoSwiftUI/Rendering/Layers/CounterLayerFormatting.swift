import Foundation

func resolveCounterAnimationDurationMs(
  displayKind: String?,
  durationMs: Int?,
  startValue: Double,
  endValue: Double
) -> Int {
  if (displayKind ?? "number") == "time" {
    return max(0, Int((abs(endValue - startValue) * 1000).rounded()))
  }
  return durationMs ?? 3_000
}

func formatCounterLayerDisplay(
  _ value: Double,
  displayKind: String?,
  decimalPlaces: Int?,
  timeFormat: String?
) -> String {
  let kind = displayKind ?? "number"
  if kind == "time" {
    return formatCounterAsTime(value, format: timeFormat ?? "mm_ss")
  }
  return formatCounterLayerValue(value, decimalPlaces: decimalPlaces ?? 0)
}

private func formatCounterLayerValue(_ value: Double, decimalPlaces: Int) -> String {
  guard value.isFinite else { return "" }
  let places = max(0, min(20, decimalPlaces))
  let formatted = String(format: "%.\(places)f", value)
  if places == 0 { return formatted }
  var trimmed = formatted
  while trimmed.hasSuffix("0") { trimmed.removeLast() }
  if trimmed.hasSuffix(".") { trimmed.removeLast() }
  return trimmed.isEmpty ? "0" : trimmed
}

private func formatCounterAsTime(_ totalSeconds: Double, format: String) -> String {
  guard totalSeconds.isFinite else { return "" }
  let whole = max(0, Int(totalSeconds.rounded(.down)))

  switch format {
  case "mm_ss":
    let minutes = whole / 60
    let seconds = whole % 60
    return "\(minutes):\(pad2(seconds))"
  case "hh_mm_ss":
    let hours = whole / 3600
    let minutes = (whole % 3600) / 60
    let seconds = whole % 60
    return "\(hours):\(pad2(minutes)):\(pad2(seconds))"
  case "dd_hh_mm_ss":
    let days = whole / 86_400
    let hours = (whole % 86_400) / 3600
    let minutes = (whole % 3600) / 60
    let seconds = whole % 60
    return "\(days):\(pad2(hours)):\(pad2(minutes)):\(pad2(seconds))"
  default:
    return ""
  }
}

private func pad2(_ n: Int) -> String {
  n < 10 ? "0\(n)" : "\(n)"
}
