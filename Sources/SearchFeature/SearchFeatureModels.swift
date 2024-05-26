import APIClient
import Foundation

public enum SearchFeature {
  public enum FetchTrending {
    public struct Response {
      static let empty = Self(coins: [], nfts: [], categories: [])
      var coins: [Coin]
      var nfts: [NFT]
      var categories: [Category]
    }
  }
  
  public enum UpdateList {
    public enum ResponseType {
      case trending(Trending.Response)
      case highlight(Highlight.Response)
    }
    
    public struct Response {
      var trendingResponse: FetchTrending.Response
      var selectedTrendingCategory: TrendingCategory
      var highlightResponse: FetchHighlight.Response
      var selectedHighlightCategory: HighlightCategory
    }
    
    public struct ViewModel {
      var dataSource: [SearchFeature.ViewModel.SectionType: [RowData]]
    }
    
    public enum Trending {
      public struct Response {
        var data: FetchTrending.Response
        var selectedCategory: TrendingCategory
      }
    }
    
    public enum Highlight {
      public struct Response {
        var data: FetchHighlight.Response
        var selectedCategory: HighlightCategory
      }
    }
  }
  
  public struct Coin {
    public var id: String
    public var coinId: Int?
    public var name: String
    public var symbol: String
    public var marketCapRank: Int?
    public var thumb: String?
    public var currentPrice: Double?
    public var priceChangePercentage24H: Double?
  }
  
  public struct NFT {
    public var id: String
    public var name: String
    public var symbol: String
    public var thumb: String
    public var floorPriceInNativeCurrency: Double
    public var floorPrice24HPercentageChange: Double
  }
  
  public struct Category {
    public var id: Int
    public var name: String
    public var marketCap1HChange: Double
  }
  
  public enum FetchHighlight {
    public struct Response {
      static let empty = Self(topGainer: [], topLoser: [], newCoins: [])
      public var topGainer: [Coin]
      public var topLoser: [Coin]
      public var newCoins: [Coin]
    }
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
    public enum SectionType: Int, Comparable {
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
      
      public static func < (
        lhs: SearchFeature.ViewModel.SectionType,
        rhs: SearchFeature.ViewModel.SectionType
      ) -> Bool {
        lhs.rawValue < rhs.rawValue
      }
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
      var tmp: String? = nil
      if let rank = rank {
        tmp = String(rank)
      }
      return .init(
        rank: tmp,
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
    
    init(
      rank: Int? = nil,
      imageUrl: String? = nil,
      name: String,
      fullname: String,
      price: Price? = nil
    ) {
      self.rank = rank
      self.imageUrl = imageUrl
      self.name = name
      self.fullname = fullname
      self.price = price
    }
  }
  
  public enum TrendingCategory: Int, Hashable, CustomStringConvertible,
                                ListCategoryable, Comparable, CaseIterable {
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
    
    public static func < (
      lhs: SearchFeature.TrendingCategory,
      rhs: SearchFeature.TrendingCategory
    ) -> Bool {
      lhs.rawValue < rhs.rawValue
    }
  }
  
  public enum HighlightCategory: Int, CustomStringConvertible, ListCategoryable, CaseIterable {
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
