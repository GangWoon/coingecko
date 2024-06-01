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
  public var load: () throws -> [RecentSearch]
  public var save: (RecentSearch) throws -> Void
}

extension RecentSearchesClient {
  public static func sqlite() throws -> Self {
    let fileManager = FileManager.default
    let url = try fileManager
      .url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      )
      .appendingPathComponent("db.sqlite3")
    let db = try Connection(url.path)
    let recentSearchs = Table("recentSearchs")
    let id = Expression<Int64>("id")
    let symbol = Expression<String>("symbol")
    let name = Expression<String?>("name")
    let thumbnail = Expression<String?>("thumbnail")
    let rank = Expression<Int?>("rank")
    try db.run(
      recentSearchs.create(ifNotExists: true) { t in
        t.column(id, primaryKey: .autoincrement)
        t.column(symbol)
        t.column(name)
        t.column(thumbnail)
        t.column(rank)
      }
    )
    
    return .init(
      load: {
        return try db.prepare(recentSearchs)
          .map {
            .init(
              id: $0[id],
              symbol: $0[symbol],
              name: $0[name],
              thumbnail: $0[thumbnail],
              rank: $0[rank]
            )
          }
      },
      save: { search in
        let existingCount = try db
          .scalar(
            recentSearchs
              .filter(name == search.name)
              .count
          )
        /// 중복 데이터 체크
        guard existingCount == 0 else { return }
        let insert = recentSearchs
          .insert(
            symbol <- search.symbol,
            name <- search.name,
            thumbnail <- search.thumbnail,
            rank <- search.rank
          )
        try db.run(insert)
        
        /// 데이터가 3개 이상일 경우, 가장 오래된 데이터 제거
        let count = try db.scalar(recentSearchs.count)
        if count > 3 {
          let deleteCount = count - 3
          let oldestRecords = try db
            .prepare(
              recentSearchs
                .order(id.asc)
                .limit(deleteCount)
            )
          for record in oldestRecords {
            try db
              .run(
                recentSearchs
                  .filter(id == record[id])
                  .delete()
              )
          }
        }
      }
    )
  }
  
  public static func test(_ recentSearches: [RecentSearch]) -> Self {
    var copy = recentSearches
    
    return .init(
      load: { copy },
      save: {
        copy.append($0)
      }
    )
  }
}
