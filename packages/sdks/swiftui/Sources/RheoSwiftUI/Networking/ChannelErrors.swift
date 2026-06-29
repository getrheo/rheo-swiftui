import Foundation

public enum RheoSDKError: Error, LocalizedError, Equatable {
  case channelRequired(String)
  case channelNotFound(String)
  case channelArchived(String)
  case unauthorized(String)
  case requestFailed(statusCode: Int, message: String)
  case missingRuntime

  public var errorDescription: String? {
    switch self {
    case .channelRequired(let message): return message
    case .channelNotFound(let message): return message
    case .channelArchived(let message): return message
    case .unauthorized(let message): return message
    case .requestFailed(_, let message): return message
    case .missingRuntime: return "RheoProvider is missing from the SwiftUI environment."
    }
  }
}

struct APIErrorEnvelope: Decodable {
  var code: String?
  var message: String?
}

func mapSDKHTTPError(statusCode: Int, data: Data) -> RheoSDKError {
  let envelope = try? JSONDecoder.rheo.decode(APIErrorEnvelope.self, from: data)
  let message = envelope?.message ?? "request failed: \(statusCode)"
  if statusCode == 400, envelope?.code == "channel_required" {
    return .channelRequired(message)
  }
  if statusCode == 404, envelope?.code == "channel_not_found" {
    return .channelNotFound(message)
  }
  if statusCode == 410, envelope?.code == "channel_archived" {
    return .channelArchived(message)
  }
  if statusCode == 401 {
    return .unauthorized(message)
  }
  return .requestFailed(statusCode: statusCode, message: message)
}
