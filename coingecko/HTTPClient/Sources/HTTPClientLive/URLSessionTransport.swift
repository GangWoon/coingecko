import HTTPClient
import Foundation

public struct URLSessionTransport: ClientTransport {
  public let session: URLSession
  
  public init(session: URLSession = .shared) {
    self.session = session
  }
  
  public func send(_ request: HTTPRequest, baseURL: URL) async throws -> HTTPResponse {
    try Task.checkCancellation()
    var urlRequest = try URLRequest(request, baseURL: baseURL)
    urlRequest.httpBody = request.body
    let (data, response) = try await session.data(for: urlRequest)
    return try HTTPResponse(response, data: data)
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

public extension URLRequest {
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
    if !request.queries.isEmpty {
      baseUrlComponents.queryItems = request.queries
        .map { .init(name: $0.name, value: $0.value) }
    }
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
      setValue(header.value, forHTTPHeaderField: header.name)
    }
  }
}

public extension HTTPResponse {
  init(_ urlResponse: URLResponse, data: Data) throws {
    guard let httpResponse = urlResponse as? HTTPURLResponse else {
      throw URLSessionTransportError.notHTTPResponse(urlResponse)
    }
    var headerFields: [HTTPField] = []
    for (headerName, headerValue) in httpResponse.allHeaderFields {
      guard
        let name = headerName as? String,
        let value = headerValue as? String
      else { continue }
      headerFields.append(.init(name: name, value: value))
    }
    self.init(
      statusCode: httpResponse.statusCode,
      headerFields: headerFields,
      body: data
    )
  }
}
