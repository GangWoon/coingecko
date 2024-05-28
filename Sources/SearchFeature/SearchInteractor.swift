import UIKit
import Foundation

public protocol SearchDataStore {
  var text: String { get }
  var sectionList: [SearchFeature.SectionType] { get }
  var selectedTrendingCategory: SearchFeature.TrendingCategory { get }
  var selectedHighlightCategory: SearchFeature.HighlightCategory { get }
}

public protocol SearchBusinessLogic {
  func prepare() async
  
  func searchFieldChanged(_ text: String?)
  func categoryTapped(_ request: SearchFeature.CategoryTapped.Request)
  func tappedExpandRow()
}

public final class SearchInteractor: SearchDataStore {
  public var text: String
  public var isTrendingExpanded: Bool
  public var selectedTrendingCategory: SearchFeature.TrendingCategory
  public var trendingCoins: [SearchFeature.Coin]
  public var trendingNFTs: [SearchFeature.NFT]
  public var trendingCategories: [SearchFeature.Category]
  
  public var selectedHighlightCategory: SearchFeature.HighlightCategory
  public var topGainer: [SearchFeature.Coin]
  public var topLoser: [SearchFeature.Coin]
  public var newCoins: [SearchFeature.Coin]
  
  // MARK: - Interface
  public var worker: any SearchWorkerInterface
  public var presenter: (any SearchPresentationLogic)?
  /// var navigate: (model) -> Void
  
  public init(
    state: State = .init(),
    worker: any SearchWorkerInterface
  ) {
    self.text = state.text
    self.isTrendingExpanded = state.isTrendingExpanded
    self.selectedTrendingCategory = state.selectedTrendingCategory
    self.trendingCoins = state.trendingCoins
    self.trendingNFTs = state.trendingNFTs
    self.trendingCategories = state.trendingCategories
    self.selectedHighlightCategory = state.selectedHighlightCategory
    self.topGainer = state.topGainer
    self.topLoser = state.topLoser
    self.newCoins = state.newCoins
    
    self.worker = worker
  }
}

extension SearchInteractor {
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
  
  public struct State {
    public var sectionList: [SearchFeature.SectionType] {
      var result: [SearchFeature.SectionType] = []
      if hasTrendingData {
        result.append(.trending)
      }
      if hasHighlightData {
        result.append(.highlight)
      }
      return result
    }
    var hasTrendingData: Bool {
      !trendingCoins.isEmpty || !trendingNFTs.isEmpty || !trendingCategories.isEmpty
    }
    var hasHighlightData: Bool {
      !trendingCoins.isEmpty || !trendingNFTs.isEmpty || !trendingCategories.isEmpty
    }
    public var trendingCategory: [SearchFeature.TrendingCategory]
    public var highlightCategory: [SearchFeature.HighlightCategory]
    public var text: String
    public var isTrendingExpanded: Bool
    public var selectedTrendingCategory: SearchFeature.TrendingCategory
    public var trendingCoins: [SearchFeature.Coin]
    public var trendingNFTs: [SearchFeature.NFT]
    public var trendingCategories: [SearchFeature.Category]
    public var selectedHighlightCategory: SearchFeature.HighlightCategory
    public var topGainer: [SearchFeature.Coin]
    public var topLoser: [SearchFeature.Coin]
    public var newCoins: [SearchFeature.Coin]
    
    public init(
      trendingCategory: [SearchFeature.TrendingCategory] = SearchFeature.TrendingCategory.allCases,
      highlightCategory: [SearchFeature.HighlightCategory] = SearchFeature.HighlightCategory.allCases,
      text: String = "",
      isTrendingExpanded: Bool = false,
      selectedTrendingCategory: SearchFeature.TrendingCategory = .coin,
      trendingCoins: [SearchFeature.Coin] = [],
      trendingNFTs: [SearchFeature.NFT] = [],
      trendingCategories: [SearchFeature.Category] = [],
      selectedHighlightCategory: SearchFeature.HighlightCategory = .topGainers,
      topGainer: [SearchFeature.Coin] = [],
      topLoser: [SearchFeature.Coin] = [],
      newCoins: [SearchFeature.Coin] = []
    ) {
      self.trendingCategory = trendingCategory
      self.highlightCategory = highlightCategory
      self.text = text
      self.isTrendingExpanded = isTrendingExpanded
      self.selectedTrendingCategory = selectedTrendingCategory
      self.trendingCoins = trendingCoins
      self.trendingNFTs = trendingNFTs
      self.trendingCategories = trendingCategories
      self.selectedHighlightCategory = selectedHighlightCategory
      self.topGainer = topGainer
      self.topLoser = topLoser
      self.newCoins = newCoins
    }
  }
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
