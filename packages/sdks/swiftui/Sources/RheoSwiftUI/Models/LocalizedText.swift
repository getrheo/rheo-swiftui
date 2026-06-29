import Foundation

public struct LocalizedText: Codable, Equatable, Sendable {
  public var `default`: String
  public var translations: [String: String]?

  public init(default: String, translations: [String: String]? = nil) {
    self.default = `default`
    self.translations = translations
  }

  public func resolve(locale: String) -> String {
    if let exact = translations?[locale] { return exact }
    let lang = locale.split(separator: "-").first.map(String.init)
    if let lang, let value = translations?[lang] { return value }
    return `default`
  }
}
