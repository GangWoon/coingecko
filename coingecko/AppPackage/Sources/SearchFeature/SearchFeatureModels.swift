import APIClient
import Foundation

public enum SearchFeature {
  public enum FetchTrending {
    public struct Response {
      static let empty = Self(state: [:])
      var state: [TrendingCategory: [RowData]]
    }
    
    struct ViewModel {
      
    }
  }
  
  public enum FetchHighlight {
    public struct Response {
      static let empty = Self(topGainer: [], topLoser: [], newCoins: [])
      var topGainer: [RowData]
      var topLoser: [RowData]
      var newCoins: [RowData]
    }
  }
  
  public enum ViewWillAppear {
    public struct Reqeuset { }
    public struct Response { }
    public struct ViewModel { }
  }
  
  public enum CategoryTapped {
    public struct Request {
      var indexPath: IndexPath
    }
    public struct Response {
      var dataSource: [SearchFeature.ViewModel.SectionType : [SearchFeature.RowData]]
    }
    public struct ViewModel {
      
    }
  }
  
  
  public struct ViewModel {
    public enum SectionType: Int, CaseIterable {
      var title: String {
        switch self {
        case .history:
          return "검색기록"
        case .trending:
          return "인기"
        case .highlight:
          return "하이라이트"
        }
      }
      case history = 0
      case trending
      case highlight
    }
    
    var sectionList: [SectionType]
    var trendingCategory: [TrendingCategory]
  }
}


public protocol ListCategoryable {
  var description: String { get }
}

extension SearchFeature {
  public struct RowData: Hashable {
    var rowState: SearchListRow.State {
      .init(
        rank: "\(rank)",
        imageUrl: URL(string: imageUrl ?? ""),
        abbreviation: name,
        fullname: fullname,
        priceInfo: price?.rowState
      )
    }
    let rank: Int?
    let imageUrl: String?
    let name: String
    let fullname: String
    let price: Price?
    public struct Price: Hashable {
      var rowState: SearchListRow.State.PriceInfo {
        .init(current: current, change24h: change24h)
      }
      let current: Double
      let change24h: Double
    }
  }
  
  public enum TrendingCategory: Int, Hashable, CustomStringConvertible, ListCategoryable {
    public var description: String {
      switch self {
      case .coin:
        return "코인"
      case .nft:
        return "NFT"
      case .category:
        return "카테고리"
      }
    }
    case coin = 0
    case nft
    case category
  }
  
  public enum HighlightCategory: Int, CustomStringConvertible, ListCategoryable {
    public var description: String {
      switch self {
      case .topGainers:
        return "상위 상승 목록"
      case .topLosers:
        return "상위 하락 목록"
      case .newListings:
        return "신규 종목"
      }
    }
    case topGainers
    case topLosers
    case newListings
  }
}
