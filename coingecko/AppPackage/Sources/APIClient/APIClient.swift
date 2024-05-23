import HTTPClientLive
import HTTPClient
import Foundation
//
public struct APIClient: Sendable {
  public var trending: @Sendable () async throws -> Operations.Trending.Output
  public var topGainerAndLoser: @Sendable () async throws -> Operations.Coin.Output
  public var newCoins: @Sendable () async throws -> Operations.Coin.Output
}
//
public  extension APIClient {
  static let live: Self = {
    let client = UniversalClient(
      serverURL: URL(string: "https://api.coingecko.com/api/v3/"),
      transport: URLSessionTransport()
    )
    
    return .init(
      trending: {
        try await client.send(input: Operations.Trending.Input()) { _ in
          HTTPRequest(path: "search/trending")
        } deserializer: { response in
          switch response.statusCode {
          case 200:
            return try .ok(.init(body: .json(decode(response.body))))
          default:
            return .undocumented(
              statusCode: response.statusCode,
              .init(headerFields: response.headerFields, body: response.body)
            )
          }
        }
      },
      topGainerAndLoser: {
        try await client
          .send(
            input: Operations.Coin.Input(),
            serializer: { _ in
              HTTPRequest(
                path: "coins/markets",
                queries: [
                  .init(name: "vs_currency", value: "usd"),
                  .init(name: "order", value: "market_cap_desc"),
                  .init(name: "per_page", value: "200"),
                  .init(name: "page", value: "1")
                ]
              )
            },
            deserializer: { response in
              switch response.statusCode {
              case 200:
                return try .ok(.init(body: .json(decode(response.body))))
              default:
                return .undocumented(
                  statusCode: response.statusCode,
                  .init(headerFields: response.headerFields, body: response.body)
                )
              }
            }
          )
      },
      newCoins: {
        try await client
          .send(
            input: Operations.Coin.Input(),
            serializer: { _ in HTTPRequest(path: "coins/list") },
            deserializer: { response in
              switch response.statusCode {
              case 200:
                return try .ok(.init(body: .json(decode(response.body))))
              default:
                return .undocumented(
                  statusCode: response.statusCode,
                  .init(headerFields: response.headerFields, body: response.body)
                )
              }
            }
          )
      }
    )
  }()
}

private func decode<T: Decodable>(_ data: Data) throws -> T {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return try decoder.decode(T.self, from: data)
}
