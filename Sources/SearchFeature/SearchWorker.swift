import APIClient
import Foundation

public protocol SearchWorkerInterface: AnyObject {
  func loadSearchHistory() -> [String]
  func saveSearchHistory()
  func getTrending() async throws -> SearchFeature.FetchTrending.Response
  func getHighlight() async throws -> SearchFeature.FetchHighlight.Response
}

public final class SearchWorker: SearchWorkerInterface {
  let apiClient: APIClient
  
  public init(apiClient: APIClient = .live) {
    self.apiClient = apiClient
  }
  
  public func loadSearchHistory() -> [String] {
    return []
  }
  
  public func saveSearchHistory() { }
  
  public func getTrending() async throws -> SearchFeature.FetchTrending.Response {
    let result = try await apiClient.trending()
    switch result {
    case .ok(let response):
      return response.body.json.toDomain()
      
    case .undocumented:
      return .empty
    }
  }
  
  public func getHighlight() async throws -> SearchFeature.FetchHighlight.Response {
    async let topGainerAndLoser = apiClient.topGainerAndLoser()
    async let newCoins = apiClient.newCoins()
//    
    try Task.checkCancellation()
    let topGainer: [SearchFeature.Coin]
    let topLoser: [SearchFeature.Coin]
    switch try await topGainerAndLoser {
    case .ok(let response):
      topGainer = response.body.json.sorted(by: >).map { $0.toDomain() }
      topLoser = response.body.json.sorted(by: <).map { $0.toDomain() }
    case .undocumented(statusCode: let code, let payload):
      topGainer = []
      topLoser = []
      fatalError()
    }
    
    try Task.checkCancellation()
    let newCoinList: [SearchFeature.Coin]
    switch try await newCoins {
    case .ok(let response):
      newCoinList = response.body.json.map { $0.toDomain() }
    case .undocumented:
      newCoinList = []
      fatalError()
    }
    
    return .init(
      topGainer: topGainer,
      topLoser: topLoser,
      newCoins: newCoinList
    )
  }
}

private extension Components.Schemas.Trending {
  func toDomain() -> SearchFeature.FetchTrending.Response {
    .init(
      coins: coins.map { $0.toDomain() },
      nfts: nfts.map { $0.toDomain() },
      categories: categories.map { $0.toDomain() }
    )
  }
}

private extension Components.Schemas.Trending.Coin {
  func toDomain() -> SearchFeature.Coin {
    .init(
      id: id,
      coinId: coinId,
      name: name,
      symbol: symbol,
      marketCapRank: marketCapRank,
      thumb: thumb
    )
  }
}

private extension Components.Schemas.Trending.NFT {
  func toDomain() -> SearchFeature.NFT {
    .init(
      id: id,
      name: name,
      symbol: symbol,
      thumb: thumb,
      floorPriceInNativeCurrency: floorPriceInNativeCurrency,
      floorPrice24HPercentageChange: floorPrice24HPercentageChange
    )
  }
}

private extension Components.Schemas.Trending.Category {
  func toDomain() -> SearchFeature.Category {
    .init(
      id: id,
      name: name,
      marketCap1HChange: marketCap1HChange
    )
  }
}

private extension Components.Schemas.Coin {
  func toDomain() -> SearchFeature.Coin {
    .init(
      id: id,
      name: name,
      symbol: symbol,
      marketCapRank: marketCapRank,
      thumb: image,
      currentPrice: currentPrice,
      priceChangePercentage24H: priceChangePercentage24H
    )
  }
}
