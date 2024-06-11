import struct HTTPClient.UndocumentedPayload
import RecentSearchesClient
import Foundation
import ApiClient

public protocol SearchWorkerInterface: Sendable {
  func loadSearchHistory() throws -> [SearchFeature.SearchApi.Response.Item]
  func saveSearchHistory(_ item: SearchFeature.SearchApi.Response.Item) throws
  func getTrending() async throws -> SearchFeature.FetchTrending.Response
  func getHighlight() async throws -> SearchFeature.FetchHighlight.Response
  func search(request: SearchFeature.SearchApi.Request) async throws -> SearchFeature.SearchApi.Response
}

public final class SearchWorker: SearchWorkerInterface, Sendable {
  let apiClient: ApiClient
  let recentSearchesClient: RecentSearchesClient
  
  public init(
    apiClient: ApiClient,
    recentSearchesClient: RecentSearchesClient
  ) {
    self.apiClient = apiClient
    self.recentSearchesClient = recentSearchesClient
  }
  
  public func loadSearchHistory() throws -> [SearchFeature.SearchApi.Response.Item] {
    try recentSearchesClient
      .load()
      .map(\.domain)
  }
  
  public func saveSearchHistory(_ item: SearchFeature.SearchApi.Response.Item) throws {
    try recentSearchesClient.save(item.row)
  }
  
  public func getTrending() async throws -> SearchFeature.FetchTrending.Response {
    let result = try await apiClient.trending()
    switch result {
    case .ok(let response):
      return response.body.json.domain
      
    case .undocumented(statusCode: let code, let payload):
      throw _Error.rateLimitExceeded(code: code, payload: payload)
    }
  }
  
  public func getHighlight() async throws -> SearchFeature.FetchHighlight.Response {
    async let topGainerAndLoser = apiClient.topGainerAndLoser()
    async let newCoins = apiClient.newCoins()
    try Task.checkCancellation()
    let topGainer: [SearchFeature.Coin]
    let topLoser: [SearchFeature.Coin]
    switch try await topGainerAndLoser {
    case .ok(let response):
      topGainer = response.body.json.sorted(by: >).map(\.domain)
      topLoser = response.body.json.sorted(by: <).map(\.domain)
    case .undocumented(statusCode: let code, let payload):
      throw _Error.rateLimitExceeded(code: code, payload: payload)
    }
    
    try Task.checkCancellation()
    let newCoinList: [SearchFeature.Coin]
    switch try await newCoins {
    case .ok(let response):
      newCoinList = response.body.json.map(\.domain)
    case .undocumented(statusCode: let code, let payload):
      throw _Error.rateLimitExceeded(code: code, payload: payload)
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
    case .undocumented(statusCode: let code, let payload):
      throw _Error.rateLimitExceeded(code: code, payload: payload)
    }
  }
}

private extension SearchWorker {
  enum _Error: Error, CustomDebugStringConvertible, LocalizedError {
    var debugDescription: String {
      switch self {
      case .rateLimitExceeded(code: let code, payload: let payload):
              """
              code: \(code)
              headerFields: \(payload.headerFields)
              body: \(
              payload.body != nil
              ? String(data: payload.body!, encoding: .utf8) ?? "<nil>"
              : "<nil>"
              )
              """
      }
    }
    
    var errorDescription: String? {
      """
      서버로 부터 데이터를 받아올 수 있는 양을 초과했습니다.
      live value가 아닌, test value로 변경시켜주세요.
      """
    }
    
    case rateLimitExceeded(code: Int, payload: UndocumentedPayload)
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

private extension RecentSearch {
  var domain: SearchFeature.SearchApi.Response.Item {
    .init(
      thumb: thumbnail ?? "",
      symbol: symbol,
      name: name,
      rank: rank
    )
  }
}

private extension SearchFeature.SearchApi.Response.Item {
  var row: RecentSearch {
    .init(
      symbol: symbol,
      name: name,
      thumbnail: thumb,
      rank: rank
    )
  }
}
