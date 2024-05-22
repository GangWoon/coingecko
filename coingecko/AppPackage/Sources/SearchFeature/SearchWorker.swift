import APIClient
import Foundation

public protocol SearchWorkerInterface: AnyObject {
  func loadSearchHistory() -> [String]
  func saveSearchHistory()
  func getTrending() async throws -> SearchFeature.FetchTrending.Response
}

public final class SearchWorker: SearchWorkerInterface {
//  let apiClient: APIClient
  
  public init(
//    apiClient: APIClient = .live
    
  ) {
//    self.apiClient = apiClient
  }
  
  public func loadSearchHistory() -> [String] {
    return []
  }
  
  public func saveSearchHistory() { }
  
  public func getTrending() async throws -> SearchFeature.FetchTrending.Response {
//    let result = try await apiClient.trending()
    fatalError()
//    switch result {
//    case .ok(let response):
//      return response.body.json.toDomain()
//      
//    case .undocumented(statusCode: let code, let payload):
//      fatalError()
//    }
  }
}

//extension Components.Schemas.Trending {
//  func toDomain() -> SearchFeature.FetchTrending.Response {
//    .init(
//      state: [
//        .coin: coins.map(\.rowData),
//        .nft: nfts.map(\.rowData),
//        .category: categories.map(\.rowData)
//      ]
//    )
//  }
//}
//
//extension Components.Schemas.Trending.Coin {
//  var rowData: SearchFeature.RowData {
//    .init(
//      rank: marketCapRank,
//      imageUrl: thumb,
//      name: symbol,
//      fullname: name,
//      price: nil
//    )
//  }
//}
//
//extension Components.Schemas.Trending.NFT {
//  var rowData: SearchFeature.RowData {
//    .init(
//      rank: nil,
//      imageUrl: self.thumb,
//      name: symbol,
//      fullname: name,
//      price: .init(
//        current: floorPriceInNativeCurrency,
//        change24h: floorPrice24HPercentageChange
//      )
//    )
//  }
//}
//
//extension Components.Schemas.Trending.Category {
//  var rowData: SearchFeature.RowData {
//    .init(
//      rank: nil,
//      imageUrl: nil,
//      name: "",
//      fullname: name,
//      price: .init(current: 0, change24h: marketCap1HChange)
//    )
//  }
//}
