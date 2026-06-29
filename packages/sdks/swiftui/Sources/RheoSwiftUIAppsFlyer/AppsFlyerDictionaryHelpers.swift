import Foundation

enum AppsFlyerDictionaryHelpers {
  static func stringKeyed(_ raw: [AnyHashable: Any]) -> [String: Any] {
    var out: [String: Any] = [:]
    out.reserveCapacity(raw.count)
    for (key, value) in raw {
      guard let k = key as? String else { continue }
      out[k] = value
    }
    return out
  }
}
