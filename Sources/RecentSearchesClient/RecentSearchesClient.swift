import Foundation
import SQLite

public struct RecentSearch {
  public var id: Int64?
  public var symbol: String
  public var name: String?
  public var thumbnail: String?
  public var rank: Int?
  
  public init(
    id: Int64? = nil,
    symbol: String,
    name: String? = nil,
    thumbnail: String? = nil,
    rank: Int? = nil
  ) {
    self.id = id
    self.symbol = symbol
    self.name = name
    self.thumbnail = thumbnail
    self.rank = rank
  }
}

public struct RecentSearchesClient {
  public var load: @Sendable () throws -> [RecentSearch]
  public var save: @Sendable (RecentSearch) throws -> Void
  
  public init(
    load: @Sendable @escaping () throws -> [RecentSearch],
    save: @Sendable @escaping (RecentSearch) throws -> Void
  ) {
    self.load = load
    self.save = save
  }
}
