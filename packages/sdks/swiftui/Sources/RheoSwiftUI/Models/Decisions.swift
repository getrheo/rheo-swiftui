import Foundation

public typealias FlowJumpTarget = String?

public enum DecisionVariableRef: Codable, Equatable, Sendable {
  case builtin(name: String)
  case sdk(key: String)
  case field(fieldKey: String)

  private enum CodingKeys: String, CodingKey {
    case kind
    case name
    case key
    case fieldKey
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(String.self, forKey: .kind)
    switch kind {
    case "builtin":
      self = .builtin(name: try container.decode(String.self, forKey: .name))
    case "sdk":
      self = .sdk(key: try container.decode(String.self, forKey: .key))
    case "field":
      self = .field(fieldKey: try container.decode(String.self, forKey: .fieldKey))
    default:
      throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown decision variable kind \(kind)")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .builtin(let name):
      try container.encode("builtin", forKey: .kind)
      try container.encode(name, forKey: .name)
    case .sdk(let key):
      try container.encode("sdk", forKey: .kind)
      try container.encode(key, forKey: .key)
    case .field(let fieldKey):
      try container.encode("field", forKey: .kind)
      try container.encode(fieldKey, forKey: .fieldKey)
    }
  }
}

public enum DecisionPredicate: Codable, Equatable, Sendable {
  case string(StringPredicate)
  case number(NumberPredicate)
  case boolean(BooleanPredicate)
  case choice(ChoicePredicate)
  case multi(MultiPredicate)

  private enum CodingKeys: String, CodingKey {
    case type
    case pred
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)
    switch type {
    case "string":
      self = .string(try container.decode(StringPredicate.self, forKey: .pred))
    case "number":
      self = .number(try container.decode(NumberPredicate.self, forKey: .pred))
    case "boolean":
      self = .boolean(try container.decode(BooleanPredicate.self, forKey: .pred))
    case "choice":
      self = .choice(try container.decode(ChoicePredicate.self, forKey: .pred))
    case "multi":
      self = .multi(try container.decode(MultiPredicate.self, forKey: .pred))
    default:
      throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown predicate type \(type)")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .string(let pred):
      try container.encode("string", forKey: .type)
      try container.encode(pred, forKey: .pred)
    case .number(let pred):
      try container.encode("number", forKey: .type)
      try container.encode(pred, forKey: .pred)
    case .boolean(let pred):
      try container.encode("boolean", forKey: .type)
      try container.encode(pred, forKey: .pred)
    case .choice(let pred):
      try container.encode("choice", forKey: .type)
      try container.encode(pred, forKey: .pred)
    case .multi(let pred):
      try container.encode("multi", forKey: .type)
      try container.encode(pred, forKey: .pred)
    }
  }
}

public struct StringPredicate: Codable, Equatable, Sendable {
  public var op: String
  public var value: String
}

public struct NumberPredicate: Codable, Equatable, Sendable {
  public var op: String
  public var value: Double
}

public struct BooleanPredicate: Codable, Equatable, Sendable {
  public var op: String
  public var value: Bool
}

public struct ChoicePredicate: Codable, Equatable, Sendable {
  public var op: String
  public var optionId: String?
  public var optionIds: [String]?
}

public struct MultiPredicate: Codable, Equatable, Sendable {
  public var op: String
  public var optionIds: [String]
}

public indirect enum DecisionExpr: Codable, Equatable, Sendable {
  case empty
  case group(op: String, children: [DecisionExpr])
  case predicate(variable: DecisionVariableRef, predicate: DecisionPredicate)

  private enum CodingKeys: String, CodingKey {
    case kind
    case op
    case children
    case variable
    case predicate
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(String.self, forKey: .kind)
    switch kind {
    case "empty":
      self = .empty
    case "group":
      self = .group(
        op: try container.decode(String.self, forKey: .op),
        children: try container.decode([DecisionExpr].self, forKey: .children)
      )
    case "predicate":
      self = .predicate(
        variable: try container.decode(DecisionVariableRef.self, forKey: .variable),
        predicate: try container.decode(DecisionPredicate.self, forKey: .predicate)
      )
    default:
      throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown decision expression kind \(kind)")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .empty:
      try container.encode("empty", forKey: .kind)
    case .group(let op, let children):
      try container.encode("group", forKey: .kind)
      try container.encode(op, forKey: .op)
      try container.encode(children, forKey: .children)
    case .predicate(let variable, let predicate):
      try container.encode("predicate", forKey: .kind)
      try container.encode(variable, forKey: .variable)
      try container.encode(predicate, forKey: .predicate)
    }
  }
}

public struct DecisionCase: Codable, Equatable, Sendable {
  public var id: String
  public var name: String?
  public var expression: DecisionExpr
  public var next: FlowJumpTarget
}

public struct DecisionNode: Codable, Equatable, Sendable {
  public var id: String
  public var name: String?
  public var cases: [DecisionCase]
  public var elseNext: FlowJumpTarget
}

public struct DecisionEvaluationTelemetry: Equatable, Sendable {
  public var decisionNodeId: String
  public var matchedCaseId: String?
  public var clauseDigest: [String]
}
