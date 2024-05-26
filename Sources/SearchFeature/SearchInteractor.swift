import Foundation

public protocol SearchDataStore {
  var text: String { get }
  var sectionList: [SearchFeature.SectionType] { get }
  var selectedTrendingCategory: SearchFeature.TrendingCategory { get set }
  
  var trendingCategory: [SearchFeature.TrendingCategory] { get }
  var selectedHighlightCategory: SearchFeature.HighlightCategory { get set }
  var highlightCategory: [SearchFeature.HighlightCategory] { get }
}

public protocol SearchBusinessLogic {
  func prepare() async
  
  func searchFieldChanged(_ text: String?)
  func categoryTapped(_ request: SearchFeature.CategoryTapped.Request)
}

public final class SearchInteractor: SearchDataStore {
  public var sectionList: [SearchFeature.SectionType] {
    var list: [SearchFeature.SectionType] = []
    if hasTrendingData {
      list.append(.trending)
    }
    if hasHighlightData {
      list.append(.highlight)
    }
    
    return list
  }
  public var trendingCategory: [SearchFeature.TrendingCategory] {
    SearchFeature.TrendingCategory.allCases
  }
  public var highlightCategory: [SearchFeature.HighlightCategory] {
    SearchFeature.HighlightCategory.allCases
  }
  
  public var dataSource: [SearchFeature.SectionType : [SearchFeature.RowData]] = [:]
  
  // MARK: - State
  public var text: String = ""
  
  var hasTrendingData: Bool {
    !trendingCoins.isEmpty || !trendingNFTs.isEmpty || !trendingCategories.isEmpty
  }
  public var selectedTrendingCategory: SearchFeature.TrendingCategory = .coin
  var trendingResponse: SearchFeature.FetchTrending.Response {
    .init(
      coins: trendingCoins,
      nfts: trendingNFTs,
      categories: trendingCategories
    )
  }
  public var trendingCoins: [SearchFeature.Coin] = []
  public var trendingNFTs: [SearchFeature.NFT] = []
  public var trendingCategories: [SearchFeature.Category] = []
  
  var hasHighlightData: Bool {
    !trendingCoins.isEmpty || !trendingNFTs.isEmpty || !trendingCategories.isEmpty
  }
  public var selectedHighlightCategory: SearchFeature.HighlightCategory = .topGainers
  var highlightResponse: SearchFeature.FetchHighlight.Response {
    .init(
      topGainer: topGainer,
      topLoser: topLoser,
      newCoins: newCoins
    )
  }
  public var topGainer: [SearchFeature.Coin] = []
  public var topLoser: [SearchFeature.Coin] = []
  public var newCoins: [SearchFeature.Coin] = []
  
  // MARK: - Interface
  public var presenter: (any SearchPresentationLogic)?
  public var worker: (any SearchWorkerInterface)!
  
  public init() {
  }
}

extension SearchInteractor: SearchBusinessLogic {
  public func searchFieldChanged(_ text: String?) {
    if let text {
      self.text = text
    }
  }
  
  public func categoryTapped(_ request: SearchFeature.CategoryTapped.Request) {
    let section = sectionList[request.indexPath.section]
    
    switch section {
    case .history:
      fatalError()
    case .trending:
      selectedTrendingCategory = SearchFeature.TrendingCategory(rawValue: request.indexPath.row) ?? selectedTrendingCategory
      Task {
        await presenter?
          .updateSection(
            .trending(.init(data: trendingResponse, selectedCategory: selectedTrendingCategory))
          )
      }
    case .highlight:
      selectedHighlightCategory = SearchFeature.HighlightCategory(rawValue: request.indexPath.row) ?? selectedHighlightCategory
      Task {
        await presenter?
          .updateSection(
            .highlight(.init(data: highlightResponse, selectedCategory: selectedHighlightCategory))
          )
      }
    }
  }
  
  public func prepare() async {
    if !worker.loadSearchHistory().isEmpty {
      dataSource[.history] = []
    }
    do {
      let trendingResponse = try await worker.getTrending()
      trendingCoins = trendingResponse.coins
      trendingNFTs = trendingResponse.nfts
      trendingCategories = trendingResponse.categories
      
      let highlightResponse = try await worker.getHighlight()
      topGainer = highlightResponse.topGainer
      topLoser = highlightResponse.topLoser
      newCoins = highlightResponse.newCoins
      
      await presenter?.updateList(
        .init(
          trendingResponse: trendingResponse,
          selectedTrendingCategory: selectedTrendingCategory,
          highlightResponse: highlightResponse,
          selectedHighlightCategory: selectedHighlightCategory
        )
      )
    } catch is CancellationError {
      
    } catch {
      
    }
  }
}
