import Foundation

/// 개발자의 역량이 가장 많이 반영되는 공간
/// 개념을 분리시키는 단위가 명확하지 않기 때문에 어색함을 많이 느낍니다.
public enum SearchFeature {
  public enum FetchTrending {
    public struct Response {
      static let empty = Self(coins: [], nfts: [], categories: [])
      var coins: [Coin]
      var nfts: [NFT]
      var categories: [Category]
    }
  }
  
  public enum FetchHighlight {
    public struct Response {
      static let empty = Self(topGainer: [], topLoser: [], newCoins: [])
      public var topGainer: [Coin]
      public var topLoser: [Coin]
      public var newCoins: [Coin]
    }
  }
  
  public enum SearchApi {
    public struct Request {
      var query: String
    }
    
    public struct Response {
      struct Item {
        var thumb: String
        var symbol: String
        var name: String?
        var rank: Int?
      }
      var coins: [Item]
      var nfts: [Item]
      var exchanges: [Item]
    }
  }
  
  public enum UpdateList {
    public enum ResponseType {
      case trending(Response.Trending)
      case highlight(Response.Highlight)
    }
    
    public struct Response {
      var trending: Trending
      public struct Trending {
        var data: FetchTrending.Response
        var isExpanded: Bool
        var selectedCategory: TrendingCategory
      }
      
      var highlight: Highlight
      public struct Highlight {
        var data: FetchHighlight.Response
        var selectedCategory: HighlightCategory
      }
    }
    
    public struct ViewModel {
      public var dataSource: [SearchFeature.SectionType: [RowData]]
    }
  }
  
  public enum CategoryTapped {
    public struct Request {
      var indexPath: IndexPath
      public init(indexPath: IndexPath) { self.indexPath = indexPath }
    }
  }
}

extension SearchFeature {
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
}

// MARK: - Read in View
/// View에서 사용되는 데이터 이지만, 모듈 끼리 통신하기 위해선 raw value(Int, String)보단
/// 의미를 갖는 형태로 구체화해서 전달하는게 좋은 느낌을 받았습니다.
/// 하지만 이런 이유 때문에 View에서 사용되는 데이터가 로직을 모아두는 곳에 존재해서 어색한 느낌을 받습니다.
extension SearchFeature {
  public struct RowData: Hashable {
    public let rank: Int?
    public let imageUrl: String?
    public let name: String
    public let fullname: String
    public let price: Price?
    public struct Price: Hashable {
      public let current: Double
      public let change24h: Double
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
  
  public enum SectionType: Int, Comparable {
    public var title: String {
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
      lhs: SearchFeature.SectionType,
      rhs: SearchFeature.SectionType
    ) -> Bool {
      lhs.rawValue < rhs.rawValue
    }
  }
  
  public enum TrendingCategory: Int, Hashable, CustomStringConvertible, Comparable, CaseIterable {
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
  
  public enum HighlightCategory: Int, CustomStringConvertible, CaseIterable {
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
