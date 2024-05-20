import HTTPInterface
import HTTPTypes
import Foundation

struct UniversalClient {
  let serverURL: URL?
  let transport: any ClientTransport
  let middlewares: [any ClientMiddleware]
  
  init(
    serverURL: URL?,
    transport: any ClientTransport,
    middlewares: [any ClientMiddleware] = []
  ) {
    self.serverURL = serverURL
    self.transport = transport
    self.middlewares = middlewares
  }
  
  func send<OperationInput, OperationOutput>(
    input: OperationInput,
    serializer: @Sendable (OperationInput) throws -> (HTTPRequest, Data?),
    deserializer: @Sendable (HTTPResponse, Data) async throws -> OperationOutput
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
    let (request, requestBody) = try await wrappingError {
      try serializer(input)
    } mapError: { error in
      makeError(error: error)
    }
    var next: @Sendable (HTTPRequest, Data?, URL) async throws -> (HTTPResponse, Data) = { _request, _body, _url in
      try await wrappingError {
        try await transport.send(_request, body: _body, baseURL: _url)
      } mapError: { error in
        makeError(
          request: request,
          requestBody: requestBody,
          baseURL: baseURL,
          error: RuntimeError.transportFailed(error)
        )
      }
    }
    
    for middleware in middlewares.reversed() {
      let tmp = next
      next = { _request, _body, _url in
        try await wrappingError {
          try await middleware.intercept(
            _request,
            body: _body,
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
    
    let (response, responseBody) = try await next(request, requestBody, baseURL)
    return try await wrappingError {
      try await deserializer(response, responseBody)
    } mapError: { error in
      makeError(
        request: request,
        baseURL: baseURL,
        response: response,
        responseBody: responseBody,
        error: error
      )
    }
  }
}
