import Foundation

public struct ApiClient: Sendable {
  public var trending: @Sendable () async throws -> Operations.Trending.Output
  public var topGainerAndLoser: @Sendable () async throws -> Operations.Coin.Output
  public var newCoins: @Sendable () async throws -> Operations.Coin.Output
  
  public init(
    trending: @Sendable @escaping () async throws -> Operations.Trending.Output,
    topGainerAndLoser: @Sendable @escaping () async throws -> Operations.Coin.Output,
    newCoins: @Sendable @escaping () async throws -> Operations.Coin.Output
  ) {
    self.trending = trending
    self.topGainerAndLoser = topGainerAndLoser
    self.newCoins = newCoins
  }
}

public func decode<T: Decodable>(_ data: Data) throws -> T {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return try decoder.decode(T.self, from: data)
}
