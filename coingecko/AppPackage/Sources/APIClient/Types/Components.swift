import Foundation

public enum Components {
  public enum Schemas {
    public struct Trending: Codable, Sendable {
      public var coins: [Coin]
      public struct Coin: Sendable, Codable {
        public var id: String
        public var coinId: Int
        public var name: String
        public var symbol: String
        public var marketCapRank: Int
        public var thumb: String
        public var small: String
        public var large: String
        public var slug: String
        public var priceBtc: Double
        public var score: Int
        public var data: ItemData
        
        enum CodingKeys: String, CodingKey {
          case item
        }
        enum ItemKeys: String, CodingKey {
          case id, coinId, name, symbol, marketCapRank,
               thumb, small, large, slug, priceBtc,
               score, data
        }
        
        public init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          let itemContainer = try container.nestedContainer(keyedBy: ItemKeys.self, forKey: .item)
          
          id = try itemContainer.decode(String.self, forKey: .id)
          coinId = try itemContainer.decode(Int.self, forKey: .coinId)
          name = try itemContainer.decode(String.self, forKey: .name)
          symbol = try itemContainer.decode(String.self, forKey: .symbol)
          marketCapRank = try itemContainer.decode(Int.self, forKey: .marketCapRank)
          thumb = try itemContainer.decode(String.self, forKey: .thumb)
          small = try itemContainer.decode(String.self, forKey: .small)
          large = try itemContainer.decode(String.self, forKey: .large)
          slug = try itemContainer.decode(String.self, forKey: .slug)
          priceBtc = try itemContainer.decode(Double.self, forKey: .priceBtc)
          score = try itemContainer.decode(Int.self, forKey: .score)
          data = try itemContainer.decode(ItemData.self, forKey: .data)
        }
        
        public func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)
          var itemContainer = container.nestedContainer(keyedBy: ItemKeys.self, forKey: .item)
          
          try itemContainer.encode(id, forKey: .id)
          try itemContainer.encode(coinId, forKey: .coinId)
          try itemContainer.encode(name, forKey: .name)
          try itemContainer.encode(symbol, forKey: .symbol)
          try itemContainer.encode(marketCapRank, forKey: .marketCapRank)
          try itemContainer.encode(thumb, forKey: .thumb)
          try itemContainer.encode(small, forKey: .small)
          try itemContainer.encode(large, forKey: .large)
          try itemContainer.encode(slug, forKey: .slug)
          try itemContainer.encode(priceBtc, forKey: .priceBtc)
          try itemContainer.encode(score, forKey: .score)
          try itemContainer.encode(data, forKey: .data)
        }
      }
      public struct ItemData: Sendable, Codable {
        public var price: Double
        public var priceBtc: String
        public var priceChangePercentage24H: [String: Double]
        public var marketCap: String
        public var marketCapBtc: String
        public var totalVolume: String
        public var totalVolumeBtc: String
        public var sparkline: String
        public var content: Content?
      }
      public struct Content: Sendable, Codable {
        public var title: String
        public var description: String
      }
      
      public var nfts: [NFT]
      public struct NFT: Sendable, Codable {
        public var id: String
        public var name: String
        public var symbol: String
        public var thumb: String
        public var nftContractId: Int
        public var nativeCurrencySymbol: String
        public var floorPriceInNativeCurrency: Double
        public var floorPrice24HPercentageChange: Double
        public var data: NftData
      }
      public struct NftData: Sendable, Codable {
        public var floorPrice: String
        public var floorPriceInUsd24HPercentageChange: String
        public var h24Volume: String
        public var h24AverageSalePrice: String
        public var sparkline: String
      }
      public var categories: [Category]
      public struct Category: Sendable, Codable {
        public var id: Int
        public var name: String
        public var marketCap1HChange: Double
        public var slug: String
        public var coinsCount: Int
        public var data: CategoryData
      }
      
      public struct CategoryData: Sendable, Codable {
        public var marketCap: Double
        public var marketCapBtc: Double
        public var totalVolume: Double
        public var totalVolumeBtc: Double
        public var marketCapChangePercentage24H: [String: Double]
        public var sparkline: String
      }
    }
  }
}
