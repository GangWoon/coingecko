import Foundation
import ApiClient

public protocol SearchWorkerInterface: AnyObject {
  func loadSearchHistory() -> [String]
  func saveSearchHistory()
  func getTrending() async throws -> SearchFeature.FetchTrending.Response
  func getHighlight() async throws -> SearchFeature.FetchHighlight.Response
  func search(request: SearchFeature.SearchApi.Request) async throws -> SearchFeature.SearchApi.Response
}

public final class SearchWorker: SearchWorkerInterface {
  let apiClient: ApiClient
  
  public init(apiClient: ApiClient) {
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
      return response.body.json.domain
      
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
      topGainer = response.body.json.sorted(by: >).map(\.domain)
      topLoser = response.body.json.sorted(by: <).map(\.domain)
    case .undocumented(statusCode: let code, let payload):
      topGainer = []
      topLoser = []
      fatalError()
    }
    
    try Task.checkCancellation()
    let newCoinList: [SearchFeature.Coin]
    switch try await newCoins {
    case .ok(let response):
      newCoinList = response.body.json.map(\.domain)
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
  
  public func search(
    request: SearchFeature.SearchApi.Request
  ) async throws -> SearchFeature.SearchApi.Response {
    let response = try await apiClient.search(.init(text: request.query))
    switch response {
    case .ok(let response):
      return response.body.json.domain
      
      
    case .undocumented:
      fatalError()
    }
  }
}

private extension Components.Schemas.Trending {
  var domain: SearchFeature.FetchTrending.Response {
    .init(
      coins: coins.map(\.domain),
      nfts: nfts.map(\.domain),
      categories: categories.map(\.domain)
    )
  }
}

private extension Components.Schemas.Trending.Coin {
  var domain: SearchFeature.Coin {
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
  var domain: SearchFeature.NFT {
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
  var domain: SearchFeature.Category {
    .init(
      id: id,
      name: name,
      marketCap1HChange: marketCap1HChange
    )
  }
}

private extension Components.Schemas.Coin {
  var domain: SearchFeature.Coin {
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

private extension Components.Schemas.Search {
  var domain: SearchFeature.SearchApi.Response {
    .init(
      coins: coins?.map(\.domain) ?? [],
      nfts: nfts?.map(\.domain) ?? [],
      exchanges: exchanges?.map(\.domain) ?? []
    )
  }
}

private extension Components.Schemas.Search.Coin {
  var domain: SearchFeature.SearchApi.Response.Item {
    .init(
      thumb: thumb,
      symbol: symbol,
      name: name,
      rank: marketCapRank
    )
  }
}

private extension Components.Schemas.Search.NFT {
  var domain: SearchFeature.SearchApi.Response.Item {
    .init(
      thumb: thumb,
      symbol: symbol,
      name: name
    )
  }
}

private extension Components.Schemas.Search.Exchange {
  var domain: SearchFeature.SearchApi.Response.Item {
    .init(thumb: thumb, symbol: name)
  }
}
