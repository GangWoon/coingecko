import protocol Foundation.LocalizedError

public enum RuntimeError: Error, CustomStringConvertible, LocalizedError {
  public var description: String { prettyDescription }
  public var prettyDescription: String {
    switch self {
    case .invalidServerURL(let string):
      return "Invalid server URL: \(string)."
    case .transportFailed:
      return "Transport threw an error."
    case .middlewareFailed(let type, _):
      return "Middleware of type '\(type)' threw an error."
    case .handlerFailed:
      return "User handler threw an error."
    case .missingRequiredResponseBody:
      return "missingRequiredResponseBody"
    }
  }
  
  var underlyingError: (any Error)? {
    switch self {
    case
        .transportFailed(let error),
        .handlerFailed(let error),
        .middlewareFailed(_, let error):
      return error
    default: return nil
    }
  }
  
  case invalidServerURL(String)
  case transportFailed(any Error)
  case middlewareFailed(middlewareType: Any.Type, any Error)
  case handlerFailed(any Error)
  case missingRequiredResponseBody
}
