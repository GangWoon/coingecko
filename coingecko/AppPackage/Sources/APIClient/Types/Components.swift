import Foundation

public enum Components {
  public enum Schemas {
    public struct Trending: Codable, Sendable {
      public var coins: [Coin]
      public struct Coin: Sendable, Codable {
        var id: String
        var coinId: Int
        var name: String
        var symbol: String
        var marketCapRank: Int
        var thumb: String
        var small: String
        var large: String
        var slug: String
        var priceBtc: Double
        var score: Int
        var data: ItemData
        
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
        var price: Double
        var priceBtc: String
        var priceChangePercentage24H: [String: Double]
        var marketCap: String
        var marketCapBtc: String
        var totalVolume: String
        var totalVolumeBtc: String
        var sparkline: String
        var content: Content?
      }
      public struct Content: Sendable, Codable {
        var title: String
        var description: String
      }
      
      public var nfts: [NFT]
      public struct NFT: Sendable, Codable {
        var id: String
        var name: String
        var symbol: String
        var thumb: String
        var nftContractId: Int
        var nativeCurrencySymbol: String
        var floorPriceInNativeCurrency: Double
        var floorPrice24HPercentageChange: Double
        var data: NftData
      }
      public struct NftData: Sendable, Codable {
        var floorPrice: String
        var floorPriceInUsd24HPercentageChange: String
        var h24Volume: String
        var h24AverageSalePrice: String
        var sparkline: String
      }
      public var categories: [Category]
      public struct Category: Sendable, Codable {
        var id: Int
        var name: String
        var marketCap1HChange: Double
        var slug: String
        var coinsCount: Int
        var data: CategoryData
      }
      
      public struct CategoryData: Sendable, Codable {
        var marketCap: Double
        var marketCapBtc: Double
        var totalVolume: Double
        var totalVolumeBtc: Double
        var marketCapChangePercentage24H: [String: Double]
        var sparkline: String
      }
    }
  }
}
