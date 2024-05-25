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
  
  public init(
    apiClient: APIClient = .test
    
  ) {
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
      fatalError()
    }
  }
  
  public func getHighlight() async throws -> SearchFeature.FetchHighlight.Response {
    async let topGainerAndLoser = apiClient.topGainerAndLoser()
    async let newCoins = apiClient.newCoins()
    
    try Task.checkCancellation()
    let topGainer: [SearchFeature.RowData]
    let topLoser: [SearchFeature.RowData]
    switch try await topGainerAndLoser {
    case .ok(let response):
      topGainer = response.body.json
        .sorted(by: >)
        .prefix(7)
        .map(\.rowData)
      topLoser = response.body.json
        .sorted(by: <)
        .prefix(7)
        .map(\.rowData)
    case .undocumented(statusCode: let code, let payload):
      topGainer = []
      topLoser = []
      fatalError()
    }
    
    try Task.checkCancellation()
    let newCoinList: [SearchFeature.RowData]
    switch try await newCoins {
    case .ok(let response):
      newCoinList = response.body.json
        .prefix(7)
        .map(\.rowData)
    
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

extension Components.Schemas.Trending {
  var minCount: Int {
    min(nfts.count, coins.count, categories.count)
  }
  
  func toDomain() -> SearchFeature.FetchTrending.Response {
    .init(
      state: [
        .coin: coins.map(\.rowData),
        .nft: Array(nfts.map(\.rowData).prefix(minCount)),
        .category: Array(categories.map(\.rowData).prefix(minCount))
      ]
    )
  }
}

extension Components.Schemas.Trending.Coin {
  var rowData: SearchFeature.RowData {
    .init(
      rank: marketCapRank,
      imageUrl: thumb,
      name: symbol,
      fullname: name,
      price: nil
    )
  }
}

extension Components.Schemas.Trending.NFT {
  var rowData: SearchFeature.RowData {
    .init(
      rank: nil,
      imageUrl: self.thumb,
      name: symbol,
      fullname: name,
      price: .init(
        current: floorPriceInNativeCurrency,
        change24h: floorPrice24HPercentageChange
      )
    )
  }
}

extension Components.Schemas.Trending.Category {
  var rowData: SearchFeature.RowData {
    .init(
      rank: nil,
      imageUrl: nil,
      name: "",
      fullname: name,
      price: .init(current: 0, change24h: marketCap1HChange)
    )
  }
}

extension Components.Schemas.Coin {
  var rowData: SearchFeature.RowData {
    .init(
      rank: marketCapRank,
      imageUrl: image,
      name: symbol,
      fullname: name,
      price: price
    )
  }
  
  var price: SearchFeature.RowData.Price? {
    if let current = currentPrice, let priceChangePercentage24H {
      return .init(current: current, change24h: priceChangePercentage24H)
    }
    return nil
  }
}
