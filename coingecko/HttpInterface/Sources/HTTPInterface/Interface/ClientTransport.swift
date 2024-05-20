import struct HTTPTypes.HTTPResponse
import struct HTTPTypes.HTTPRequest
import struct Foundation.Data
import struct Foundation.URL

public protocol ClientTransport: Sendable {
  func send(
    _ request: HTTPRequest,
    body: Data?,
    baseURL: URL
  ) async throws -> (HTTPResponse, Data)
}

public protocol ClientMiddleware: Sendable {
  func intercept(
    _ request: HTTPRequest,
    body: Data?,
    baseURL: URL,
    next: (HTTPRequest, Data?, URL) async throws -> (HTTPResponse, Data)
  ) async throws -> (HTTPResponse, Data)
}
