import HTTPInterface
import Foundation
import HTTPTypes

struct URLSessionTransport: ClientTransport {
  let session: URLSession
  
  init(session: URLSession = .shared) {
    self.session = session
  }
  
  func send(
    _ request: HTTPRequest,
    body: Data?,
    baseURL: URL
  ) async throws -> (HTTPResponse, Data) {
    try Task.checkCancellation()
    var urlRequest = try URLRequest(request, baseURL: baseURL)
    urlRequest.httpBody = body
    let (data, response) = try await session.data(for: urlRequest)
    return (try HTTPResponse(response), data)
  }
}

enum URLSessionTransportError: Error {
  case invalidRequestURL(path: String, method: HTTPRequest.Method, baseURL: URL)
  case notHTTPResponse(URLResponse)
  case noResponse(url: URL?)
}

extension URLSessionTransportError: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .invalidRequestURL(path: path, method: method, baseURL: baseURL):
      "Invalid request URL from request path: \(path), method: \(method), relative to base URL: \(baseURL.absoluteString)"
    case .notHTTPResponse(let response):
      "Received a non-HTTP response, of type: \(String(describing: type(of: response)))"
    case .noResponse(let url): 
      "Received a nil response for \(url?.absoluteString ?? "<nil URL>")"
    }
  }
}

extension URLRequest {
  init(_ request: HTTPRequest, baseURL: URL) throws {
    guard
      var baseUrlComponents = URLComponents(string: baseURL.absoluteString),
      let requestUrlComponents = URLComponents(string: request.path ?? "")
    else {
      throw URLSessionTransportError.invalidRequestURL(
        path: request.path ?? "<nil>",
        method: request.method,
        baseURL: baseURL
      )
    }
    let path = requestUrlComponents.percentEncodedPath
    baseUrlComponents.percentEncodedPath += path
    baseUrlComponents.percentEncodedQuery = requestUrlComponents.percentEncodedQuery
    guard let url = baseUrlComponents.url else {
      throw URLSessionTransportError.invalidRequestURL(
        path: path,
        method: request.method,
        baseURL: baseURL
      )
    }
    self.init(url: url)
    self.httpMethod = request.method.rawValue
    for header in request.headerFields {
      setValue(header.value, forHTTPHeaderField: header.name.canonicalName)
    }
  }
}

extension HTTPResponse {
  init(_ urlResponse: URLResponse) throws {
    guard let httpResponse = urlResponse as? HTTPURLResponse else {
      throw URLSessionTransportError.notHTTPResponse(urlResponse)
    }
    var headerFields = HTTPFields()
    for (headerName, headerValue) in httpResponse.allHeaderFields {
      guard let rawName = headerName as? String, let name = HTTPField.Name(rawName),
            let value = headerValue as? String
      else { continue }
      headerFields[name] = value
    }
    self.init(status: .init(code: httpResponse.statusCode), headerFields: headerFields)
  }
}
