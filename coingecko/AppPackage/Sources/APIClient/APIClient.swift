import HTTPInterface
import Foundation
import HTTPTypes

public struct APIClient: Sendable {
  public var trending: @Sendable () async throws -> Operations.Trending.Output
  public var highlight: @Sendable () async throws -> Operations.Highlight.Output
}

public  extension APIClient {
  static let live: Self = {
    let client = UniversalClient(
      serverURL: URL(string: "https://api.coingecko.com/api/v3"),
      transport: URLSessionTransport()
    )
    let converter = Converter()
    
    return .init(
      trending: {
        try await client.send(input: Operations.Trending.Input()) { _ in
          let a = HTTPRequest(path: "/search/trending", method: .get)
          
          return (HTTPRequest(path: "/search/trending", method: .get), nil)
        } deserializer: { response, responseBody in
          switch response.status.code {
          case 200:
            let body = try converter
              .getResponseBodyAsJson(
                Components.Schemas.Trending.self,
                from: responseBody,
                transforming: Operations.Trending.Output.Ok.Body.json
              )
            return .ok(.init(body: body))
          default:
            return .undocumented(
              statusCode: response.status.code,
              .init(headerFields: response.headerFields, body: responseBody)
            )
          }
        }
      },
      highlight: {
        fatalError()
//        try await client
//          .send(
//            input: Operations.Highlight.Input(),
//            serializer: { input in
//              var request = HTTPRequest(path: "/coins/markets?vs_currency=usd", method: .get)
//              fatalError()
//            },
//            deserializer: { _, _ in
//              fatalError()
//            }
//          )
      }
    )
  }()
}

