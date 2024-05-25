import struct Foundation.URL

public protocol ClientTransport: Sendable {
  func send(_ request: HTTPRequest, baseURL: URL) async throws -> HTTPResponse
}

public protocol ClientMiddleware: Sendable {
  func intercept(
    _ request: HTTPRequest,
    baseURL: URL,
    next: @Sendable (HTTPRequest, URL) async throws -> HTTPResponse
  ) async throws -> HTTPResponse
}
