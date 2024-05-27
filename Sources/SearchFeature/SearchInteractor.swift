import Foundation

public protocol SearchDataStore {
  var text: String { get }
  var sectionList: [SearchFeature.SectionType] { get }
  var selectedTrendingCategory: SearchFeature.TrendingCategory { get }
  
  var trendingCategory: [SearchFeature.TrendingCategory] { get }
  var selectedHighlightCategory: SearchFeature.HighlightCategory { get }
  var highlightCategory: [SearchFeature.HighlightCategory] { get }
}

public protocol SearchBusinessLogic {
  func prepare() async
  
  func searchFieldChanged(_ text: String?)
  func categoryTapped(_ request: SearchFeature.CategoryTapped.Request)
  func tappedExpandRow()
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
  var hasTrendingData: Bool {
    !trendingCoins.isEmpty || !trendingNFTs.isEmpty || !trendingCategories.isEmpty
  }
  var hasHighlightData: Bool {
    !trendingCoins.isEmpty || !trendingNFTs.isEmpty || !trendingCategories.isEmpty
  }
  
  public var trendingCategory: [SearchFeature.TrendingCategory] {
    SearchFeature.TrendingCategory.allCases
  }
  public var highlightCategory: [SearchFeature.HighlightCategory] {
    SearchFeature.HighlightCategory.allCases
  }
  
  // MARK: - State
  public var text: String = ""
  
  public var isTrendingExpanded: Bool = false
  public var selectedTrendingCategory: SearchFeature.TrendingCategory = .coin
  public var trendingCoins: [SearchFeature.Coin] = []
  public var trendingNFTs: [SearchFeature.NFT] = []
  public var trendingCategories: [SearchFeature.Category] = []
  
  public var selectedHighlightCategory: SearchFeature.HighlightCategory = .topGainers
  public var topGainer: [SearchFeature.Coin] = []
  public var topLoser: [SearchFeature.Coin] = []
  public var newCoins: [SearchFeature.Coin] = []
  
  // MARK: - Interface
  public var presenter: (any SearchPresentationLogic)?
  public var worker: (any SearchWorkerInterface)!
  
  public init() { }
}

extension SearchInteractor: SearchBusinessLogic {
  public func prepare() async {
    if !worker.loadSearchHistory().isEmpty {
      
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
      
      await presenter?.updateList(updateListResponse)
    } catch is CancellationError {
      
    } catch {
      
    }
  }
  
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
        await presenter?.updateSection(.trending(updateTrending))
      }
    case .highlight:
      selectedHighlightCategory = SearchFeature.HighlightCategory(rawValue: request.indexPath.row) ?? selectedHighlightCategory
      Task {
        await presenter?.updateSection(.highlight(updateHighlight))
      }
    }
  }
  
  public func tappedExpandRow() {
    isTrendingExpanded = true
    Task {
      await presenter?.updateSection(.trending(updateTrending))
    }
  }
}

private extension SearchInteractor {
  var updateListResponse: SearchFeature.UpdateList.Response {
    .init(
      trending: updateTrending,
      highlight: updateHighlight
    )
  }
  
  var updateTrending: SearchFeature.UpdateList.Response.Trending {
    .init(
      data: trendingResponse,
      isExpanded: isTrendingExpanded,
      selectedCategory: selectedTrendingCategory
    )
  }
  var trendingResponse: SearchFeature.FetchTrending.Response {
    .init(
      coins: trendingCoins,
      nfts: trendingNFTs,
      categories: trendingCategories
    )
  }
  
  
  var updateHighlight: SearchFeature.UpdateList.Response.Highlight {
    .init(
      data: highlightResponse,
      selectedCategory: selectedHighlightCategory
    )
  }
  var highlightResponse: SearchFeature.FetchHighlight.Response {
    .init(
      topGainer: topGainer,
      topLoser: topLoser,
      newCoins: newCoins
    )
  }
}
