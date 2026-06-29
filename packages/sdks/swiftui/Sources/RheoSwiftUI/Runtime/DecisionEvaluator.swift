import Foundation

public struct DecisionEvaluationContext: Sendable {
  public var locale: String
  public var platform: String
  public var sdkAttributes: [String: JSONValue]
  public var responses: [String: StepResponse]
}

public struct DecisionEvaluationResult: Sendable {
  public var next: FlowJumpTarget
  public var matchedCaseId: String?
  public var clauseDigest: [String]
}

public func evaluateDecisionNode(
  _ node: DecisionNode,
  context: DecisionEvaluationContext
) -> DecisionEvaluationResult {
  var digest: [String] = []
  for c in node.cases {
    let matched = evaluateDecisionExpr(c.expression, context: context)
    digest.append("\(c.id):\(matched ? "1" : "0")")
    if matched {
      return DecisionEvaluationResult(next: c.next, matchedCaseId: c.id, clauseDigest: digest)
    }
  }
  return DecisionEvaluationResult(next: node.elseNext, matchedCaseId: nil, clauseDigest: digest)
}

public func evaluateDecisionExpr(_ expr: DecisionExpr, context: DecisionEvaluationContext) -> Bool {
  switch expr {
  case .empty:
    return false
  case .group(let op, let children):
    if op == "or" {
      return children.contains { evaluateDecisionExpr($0, context: context) }
    }
    return children.allSatisfy { evaluateDecisionExpr($0, context: context) }
  case .predicate(let variable, let predicate):
    let value = decisionValue(variable, context: context)
    return evaluatePredicate(predicate, against: value)
  }
}

private func decisionValue(_ variable: DecisionVariableRef, context: DecisionEvaluationContext) -> JSONValue? {
  switch variable {
  case .builtin(let name):
    if name == "locale" { return .string(context.locale) }
    if name == "platform" { return .string(context.platform) }
    return nil
  case .sdk(let key):
    return context.sdkAttributes[key]
  case .field(let fieldKey):
    guard let response = context.responses[fieldKey] else { return nil }
    return stepResponseToCompletionValue(response)
  }
}

private func evaluatePredicate(_ predicate: DecisionPredicate, against value: JSONValue?) -> Bool {
  switch predicate {
  case .string(let pred):
    guard case .string(let str)? = value else { return false }
    switch pred.op {
    case "eq": return str == pred.value
    case "neq": return str != pred.value
    case "contains": return str.localizedCaseInsensitiveContains(pred.value)
    default: return false
    }
  case .number(let pred):
    let number: Double?
    if case .number(let n)? = value {
      number = n
    } else if case .string(let s)? = value {
      number = Double(s)
    } else {
      number = nil
    }
    guard let number else { return false }
    switch pred.op {
    case "eq": return number == pred.value
    case "neq": return number != pred.value
    case "lt": return number < pred.value
    case "lte": return number <= pred.value
    case "gt": return number > pred.value
    case "gte": return number >= pred.value
    default: return false
    }
  case .boolean(let pred):
    guard case .bool(let bool)? = value else { return false }
    switch pred.op {
    case "eq": return bool == pred.value
    case "neq": return bool != pred.value
    default: return false
    }
  case .choice(let pred):
    guard case .string(let selected)? = value else { return false }
    switch pred.op {
    case "eq": return selected == pred.optionId
    case "one_of": return pred.optionIds?.contains(selected) == true
    default: return false
    }
  case .multi(let pred):
    guard case .array(let values)? = value else { return false }
    let selected = Set(values.compactMap(\.stringValue))
    let expected = Set(pred.optionIds)
    switch pred.op {
    case "intersects": return !selected.isDisjoint(with: expected)
    case "contains_all": return expected.isSubset(of: selected)
    case "subset_of": return selected.isSubset(of: expected)
    default: return false
    }
  }
}
