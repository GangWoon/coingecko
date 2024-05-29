import protocol Foundation.LocalizedError
import struct Foundation.Data
import struct Foundation.URL
@_exported import HTTPClient

public struct UniversalClient: Sendable {
  let serverURL: URL?
  var transport: any ClientTransport
  var middlewares: [any ClientMiddleware]
  
  public init(
    serverURL: URL?,
    transport: any ClientTransport,
    middlewares: [any ClientMiddleware] = []
  ) {
    self.serverURL = serverURL
    self.transport = transport
    self.middlewares = middlewares
  }
  
  public func send<OperationInput, OperationOutput>(
    input: OperationInput,
    serializer: @Sendable (OperationInput) throws -> HTTPRequest,
    deserializer: @Sendable (HTTPResponse) async throws -> OperationOutput
  ) async throws -> OperationOutput
  where OperationOutput: Sendable, OperationInput: Sendable {
    @Sendable func wrappingError<R>(
      work: () async throws -> R,
      mapError: (any Error) -> any Error
    ) async throws -> R {
      do { return try await work() }
      catch let error as ClientError { throw error }
      catch { throw mapError(error) }
    }
    guard let baseURL = serverURL else {
      throw RuntimeError.invalidServerURL(serverURL?.absoluteString ?? "")
    }
    @Sendable func makeError(
      request: HTTPRequest? = nil,
      requestBody: Data? = nil,
      baseURL: URL? = nil,
      response: HTTPResponse? = nil,
      responseBody: Data? = nil,
      error: any Error
    ) -> any Error {
      if var error = error as? ClientError {
        error.request = error.request ?? request
        error.requestBody = error.requestBody ?? requestBody
        error.baseURL = error.baseURL ?? baseURL
        error.response = error.response ?? response
        error.responseBody = error.responseBody ?? responseBody
        return error
      }
      let causeDescription: String
      let underlyingError: any Error
      if let runtimeError = error as? RuntimeError {
        causeDescription = runtimeError.prettyDescription
        underlyingError = runtimeError.underlyingError ?? error
      } else {
        causeDescription = "Unknown"
        underlyingError = error
      }
      return ClientError(
        operationInput: input,
        request: request,
        baseURL: baseURL,
        response: response,
        causeDescription: causeDescription,
        underlyingError: underlyingError
      )
    }
    let request = try await wrappingError {
      try serializer(input)
    } mapError: { error in
      makeError(error: error)
    }
    var next: @Sendable (HTTPRequest, URL) async throws -> HTTPResponse = { _request, _url in
      try await wrappingError {
        try await transport.send(_request, baseURL: _url)
      } mapError: { error in
        makeError(
          request: request,
          requestBody: request.body,
          baseURL: baseURL,
          error: RuntimeError.transportFailed(error)
        )
      }
    }
    
    for middleware in middlewares.reversed() {
      let tmp = next
      next = { _request, _url in
        try await wrappingError {
          try await middleware.intercept(
            _request,
            baseURL: _url,
            next: tmp
          )
        } mapError: { error in
          makeError(
            request: request,
            baseURL: baseURL,
            error: RuntimeError.middlewareFailed(middlewareType: type(of: middleware), error)
          )
        }
      }
    }
    
    let response = try await next(request, baseURL)
    return try await wrappingError {
      try await deserializer(response)
    } mapError: { error in
      makeError(
        request: request,
        baseURL: baseURL,
        response: response,
        responseBody: response.body,
        error: error
      )
    }
  }
}

