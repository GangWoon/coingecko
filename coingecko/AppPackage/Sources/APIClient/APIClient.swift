import HTTPInterface
import Foundation
import HTTPTypes

public struct APIClient: Sendable {
  public var trending: @Sendable () async throws -> Operations.trending.Output
}

public  extension APIClient {
  static let live: Self = {
    let client = UniversalClient(
      serverURL: URL(string: "https://api.coingecko.com/api/v3"),
      transport: URLSessionTransport()
    )
    let converter = Converter()
    
    return .init {
      try await client.send(input: Operations.trending.Input()) { _ in
        return (HTTPRequest(path: "/search/trending", method: .get), nil)
      } deserializer: { response, responseBody in
        switch response.status.code {
        case 200:
          let body = try converter
            .getResponseBodyAsJson(
              Components.Schemas.Trending.self,
              from: responseBody,
              transforming: Operations.trending.Output.Ok.Body.json
            )
          return .ok(.init(body: body))
        default:
          return .undocumented(
            statusCode: response.status.code,
            .init(headerFields: response.headerFields, body: responseBody)
          )
        }
      }
    }
  }()
}

