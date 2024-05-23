import struct Foundation.Data
import struct Foundation.URL

protocol PrettyStringConvertible {
  var prettyDescription: String { get }
}

public struct ClientError: Error {
  public var operationInput: (any Sendable)?
  public var request: HTTPRequest?
  public var requestBody: Data?
  public var baseURL: URL?
  public var response: HTTPResponse?
  public var responseBody: Data?
  public var causeDescription: String
  public var underlyingError: any Error
  
  public init(
    operationInput: (any Sendable)?,
    request: HTTPRequest? = nil,
    requestBody: Data? = nil,
    baseURL: URL? = nil,
    response: HTTPResponse? = nil,
    responseBody: Data? = nil,
    causeDescription: String,
    underlyingError: any Error
  ) {
    self.operationInput = operationInput
    self.request = request
    self.requestBody = requestBody
    self.baseURL = baseURL
    self.response = response
    self.responseBody = responseBody
    self.causeDescription = causeDescription
    self.underlyingError = underlyingError
  }
  
  public var underlyingErrorDescription: String {
    guard let prettyError = underlyingError as? (any PrettyStringConvertible) else {
      return underlyingError.localizedDescription
    }
    return prettyError.prettyDescription
  }
}
