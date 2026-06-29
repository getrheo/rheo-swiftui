import Foundation

public struct Theme: Codable, Equatable, Sendable {
  public var primary: ThemedColor?
  public var primaryForeground: ThemedColor?
  public var background: ThemedColor?
  public var foreground: ThemedColor?
  public var accent: ThemedColor?
  public var borderRadius: Double?
  public var fontFamily: String?
}

public struct BuilderMeta: Codable, Equatable, Sendable {
  public var raw: [String: JSONValue]

  public init(raw: [String: JSONValue] = [:]) {
    self.raw = raw
  }

  public init(from decoder: Decoder) throws {
    let value = try JSONValue(from: decoder)
    if case .object(let object) = value {
      raw = object
    } else {
      raw = [:]
    }
  }

  public func encode(to encoder: Encoder) throws {
    try raw.encode(to: encoder)
  }
}

public struct FlowManifest: Codable, Equatable, Sendable {
  public var flowId: String
  public var schemaVersion: Int?
  public var version: Int
  public var defaultLocale: String
  public var locales: [String]
  public var entryScreenId: String?
  public var screens: [Screen]
  public var decisionNodes: [DecisionNode]
  public var externalSurfaceNodes: [ExternalSurfaceNode]
  public var sdkAttributeKeys: [String]
  public var theme: Theme?
  public var builderMeta: BuilderMeta

  private enum CodingKeys: String, CodingKey {
    case flowId
    case schemaVersion
    case version
    case defaultLocale
    case locales
    case entryScreenId
    case screens
    case decisionNodes
    case externalSurfaceNodes
    case sdkAttributeKeys
    case theme
    case builderMeta
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    flowId = try container.decode(String.self, forKey: .flowId)
    schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
    version = try container.decode(Int.self, forKey: .version)
    defaultLocale = try container.decode(String.self, forKey: .defaultLocale)
    locales = try container.decode([String].self, forKey: .locales)
    entryScreenId = try container.decodeIfPresent(String.self, forKey: .entryScreenId)
    screens = try container.decode([Screen].self, forKey: .screens)
    decisionNodes = try container.decodeIfPresent([DecisionNode].self, forKey: .decisionNodes) ?? []
    externalSurfaceNodes = try container.decodeIfPresent([ExternalSurfaceNode].self, forKey: .externalSurfaceNodes) ?? []
    sdkAttributeKeys = try container.decodeIfPresent([String].self, forKey: .sdkAttributeKeys) ?? []
    theme = try container.decodeIfPresent(Theme.self, forKey: .theme)
    builderMeta = try container.decodeIfPresent(BuilderMeta.self, forKey: .builderMeta) ?? BuilderMeta()
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(flowId, forKey: .flowId)
    try container.encodeIfPresent(schemaVersion, forKey: .schemaVersion)
    try container.encode(version, forKey: .version)
    try container.encode(defaultLocale, forKey: .defaultLocale)
    try container.encode(locales, forKey: .locales)
    try container.encodeIfPresent(entryScreenId, forKey: .entryScreenId)
    try container.encode(screens, forKey: .screens)
    try container.encode(decisionNodes, forKey: .decisionNodes)
    try container.encode(externalSurfaceNodes, forKey: .externalSurfaceNodes)
    try container.encode(sdkAttributeKeys, forKey: .sdkAttributeKeys)
    try container.encodeIfPresent(theme, forKey: .theme)
    try container.encode(builderMeta, forKey: .builderMeta)
  }
}

extension FlowManifest {
  public func screen(id: String) -> Screen? {
    screens.first { $0.id == id }
  }

  public func decisionNode(id: String) -> DecisionNode? {
    decisionNodes.first { $0.id == id }
  }

  public func externalSurface(id: String) -> ExternalSurfaceNode? {
    externalSurfaceNodes.first { $0.id == id }
  }
}
