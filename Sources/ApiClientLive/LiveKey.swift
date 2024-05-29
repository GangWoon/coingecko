import HTTPClientLive
import Foundation
import ApiClient

public extension ApiClient {
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
                  .init(name: "per_page", value: "10"),
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
