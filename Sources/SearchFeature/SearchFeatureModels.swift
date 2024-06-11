import Foundation

/// 개발자의 역량이 가장 많이 반영되는 공간
/// 개념을 분리시키는 단위가 명확하지 않기 때문에 어색함을 많이 느낍니다.
public enum SearchFeature {
  public enum FetchTrending {
    public struct Response: Equatable, Sendable {
      static let empty = Self(coins: [], nfts: [], categories: [])
      var coins: [Coin]
      var nfts: [NFT]
      var categories: [Category]
    }
  }
  
  public enum FetchHighlight {
    public struct Response: Equatable, Sendable {
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
    
    public struct Response: Equatable, Sendable {
      public struct Item: Equatable, Sendable {
        var thumb: String
        var symbol: String
        var name: String?
        var rank: Int?
        public init(
          thumb: String,
          symbol: String,
          name: String? = nil,
          rank: Int? = nil
        ) {
          self.thumb = thumb
          self.symbol = symbol
          self.name = name
          self.rank = rank
        }
      }
      var coins: [Item]
      var nfts: [Item]
      var exchanges: [Item]
    }
  }
  
  public enum UpdateList {
    public enum ResponseType {
      case trending(Response.Information.Trending)
      case highlight(Response.Information.Highlight)
    }
    
    public enum Response: Equatable {
      case information(Information)
      public struct Information: Equatable {
        public var recentSearchs: [SearchApi.Response.Item]
        public var trending: Trending
        public struct Trending: Equatable {
          var data: FetchTrending.Response
          var isExpanded: Bool
          var selectedCategory: TrendingCategory
        }
        
        public var highlight: Highlight
        public struct Highlight: Equatable {
          var data: FetchHighlight.Response
          var selectedCategory: HighlightCategory
        }
      }
      case loading
      case search(SearchApi.Response)
    }
    
    public enum ViewModel: Equatable {
      case information([SearchFeature.SectionType: [RowData]])
      case loading
      case search([SearchFeature.SectionType: [RowData]])
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
  public struct Coin: Equatable, Sendable {
    public var id: String
    public var coinId: Int?
    public var name: String
    public var symbol: String
    public var marketCapRank: Int?
    public var thumb: String?
    public var currentPrice: Double?
    public var priceChangePercentage24H: Double?
    
    public init(
      id: String,
      coinId: Int? = nil,
      name: String,
      symbol: String,
      marketCapRank: Int? = nil,
      thumb: String? = nil,
      currentPrice: Double? = nil,
      priceChangePercentage24H: Double? = nil
    ) {
      self.id = id
      self.coinId = coinId
      self.name = name
      self.symbol = symbol
      self.marketCapRank = marketCapRank
      self.thumb = thumb
      self.currentPrice = currentPrice
      self.priceChangePercentage24H = priceChangePercentage24H
    }
  }
  
  public struct NFT: Equatable, Sendable {
    public var id: String
    public var name: String
    public var symbol: String
    public var thumb: String
    public var floorPriceInNativeCurrency: Double
    public var floorPrice24HPercentageChange: Double
    
    public init(
      id: String,
      name: String,
      symbol: String,
      thumb: String,
      floorPriceInNativeCurrency: Double,
      floorPrice24HPercentageChange: Double
    ) {
      self.id = id
      self.name = name
      self.symbol = symbol
      self.thumb = thumb
      self.floorPriceInNativeCurrency = floorPriceInNativeCurrency
      self.floorPrice24HPercentageChange = floorPrice24HPercentageChange
    }
  }
  
  public struct Category: Equatable, Sendable {
    public var id: Int
    public var name: String
    public var marketCap1HChange: Double
    
    public init(
      id: Int,
      name: String,
      marketCap1HChange: Double
    ) {
      self.id = id
      self.name = name
      self.marketCap1HChange = marketCap1HChange
    }
  }
}

// MARK: - Read in View
/// View에서 사용되는 데이터 이지만, 모듈 끼리 통신하기 위해선 raw value(Int, String)보단
/// 의미를 갖는 형태로 구체화해서 전달하는게 좋은 느낌을 받았습니다.
/// 하지만 이런 이유 때문에 View에서 사용되는 데이터가 로직을 모아두는 곳에 존재해서 어색한 느낌을 받습니다.
extension SearchFeature {
  public struct RowData: Hashable, Identifiable, Sendable {
    public let id: UUID = .init()
    public let rank: Int?
    public let imageUrl: String?
    public let name: String
    public let fullname: String
    public let price: Price?
    public struct Price: Hashable, Sendable {
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
  
  public enum SectionType: Comparable, Hashable, Equatable, Sendable {
    public var title: String {
      switch self {
      case .history:
        return "검색기록"
      case .trending:
        return "인기"
      case .highlight:
        return "하이라이트"
      case .coin:
        return "코인"
      case .nft:
        return "NFT"
      case .exchange:
        return "교환소"
      }
    }
    public var value: (Int, Int?) {
      switch self {
      case .history:
        return (0, nil)
      case .trending(let row):
        return (1, row)
      case .highlight(let row):
        return (2, row)
      case .coin:
        return (3, nil)
      case .nft:
        return (4, nil)
      case .exchange:
        return (5, nil)
      }
    }
    case history
    case trending(Int)
    case highlight(Int)
    case coin
    case nft
    case exchange
    
    public static func < (
      lhs: SearchFeature.SectionType,
      rhs: SearchFeature.SectionType
    ) -> Bool {
      lhs.value.0 < rhs.value.0
    }
    
    public static func == (
      lhs: SearchFeature.SectionType,
      rhs: SearchFeature.SectionType
    ) -> Bool {
      lhs.value.0 == rhs.value.0
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
