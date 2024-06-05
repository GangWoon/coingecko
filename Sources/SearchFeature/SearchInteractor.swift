import struct UIKit.IndexPath
import Foundation
import CombineExt
import Combine

// MARK: - Read in View
public protocol SearchBusinessLogic {
  func prepare() async
  
  func searchFieldChanged(_ text: String?)
  func categoryTapped(_ request: SearchFeature.CategoryTapped.Request)
  func tappedExpandRow()
}

public final class SearchInteractor {
  private var textStream: CurrentValueSubject<String, Never> = .init("")
  
  public var isTrendingExpanded: Bool = false
  public var selectedTrendingCategory: SearchFeature.TrendingCategory = .coin
  public var trendingCoins: [SearchFeature.Coin] = []
  public var trendingNFTs: [SearchFeature.NFT] = []
  public var trendingCategories: [SearchFeature.Category] = []
  
  public var selectedHighlightCategory: SearchFeature.HighlightCategory = .topGainers
  public var topGainer: [SearchFeature.Coin] = []
  public var topLoser: [SearchFeature.Coin] = []
  public var newCoins: [SearchFeature.Coin] = []
  
  public var searchResults: SearchFeature.SearchApi.Response?
  public var recentSearches: [SearchFeature.SearchApi.Response.Item] = []
  
  // MARK: - Interface
  public var worker: any SearchWorkerInterface
  public var presenter: (any SearchPresentationLogic)?
  /// var navigate: (model) -> Void
  
  private var cancellables: [AnyHashable: Task<Void, Never>] = [:]
  private var _lock: NSLock = .init()
  
  public init(worker: any SearchWorkerInterface) {
    self.worker = worker
  }
  
  private func run(
    id: AnyHashable = UUID(),
    @_implicitSelfCapture work: @Sendable @escaping () async throws -> Void,
    @_implicitSelfCapture errorHandler: @Sendable @escaping (Error) async -> Void = { _ in }
  ){
    @Sendable func lock(_ work: @Sendable @escaping () -> Void) {
      _lock.lock()
      work()
      _lock.unlock()
    }
    let task = Task {
      defer {
        lock { [weak self] in
          self?.cancellables[id] = nil
        }
      }
      do {
        try await work()
      } catch {
        guard !Task.isCancelled else { return }
        await errorHandler(error)
      }
    }
    
    lock { [weak self] in
      self?.cancellables[id] = task
    }
  }
}

extension SearchInteractor {
  var sectionList: [SearchFeature.SectionType] {
    var list: [SearchFeature.SectionType] = []
    if let searchResults {
      if !searchResults.coins.isEmpty {
        list.append(.coin)
      }
      if !searchResults.nfts.isEmpty {
        list.append(.nft)
      }
      if !searchResults.exchanges.isEmpty {
        list.append(.exchange)
      }
    } else {
      if !recentSearches.isEmpty {
        list.append(.history)
      }
      if hasTrendingData {
        list.append(.trending(selectedTrendingCategory.rawValue))
      }
      if hasHighlightData {
        list.append(.highlight(selectedHighlightCategory.rawValue))
      }
    }
    
    return list
  }
  var hasTrendingData: Bool {
    !trendingCoins.isEmpty || !trendingNFTs.isEmpty || !trendingCategories.isEmpty
  }
  var hasHighlightData: Bool {
    !trendingCoins.isEmpty || !trendingNFTs.isEmpty || !trendingCategories.isEmpty
  }
}

// MARK: - BusinessLogic
extension SearchInteractor: SearchBusinessLogic {
  public func prepare() async {
    do {
      let loaded = try worker.loadSearchHistory()
      if !loaded.isEmpty {
        recentSearches = loaded
      }
      let trendingResponse = try await worker.getTrending()
      trendingCoins = trendingResponse.coins
      trendingNFTs = trendingResponse.nfts
      trendingCategories = trendingResponse.categories
      
      let highlightResponse = try await worker.getHighlight()
      topGainer = highlightResponse.topGainer
      topLoser = highlightResponse.topLoser
      newCoins = highlightResponse.newCoins
      
      await presenter?.updateList(updateListResponse)
    } catch {
      guard !(error is CancellationError) else { return }
      await presenter?.presentAlert(message: error.localizedDescription)
    }
  }
  
  public func searchFieldChanged(_ text: String?) {
    guard
      let text, !text.isEmpty
    else {
      cancelSearchApiTask()
      return
    }
    buildTextStream()
    textStream.send(text)
    run { await presenter?.updateList(.loading) }
  }
  
  private func buildTextStream() {
    let id: AnyHashable = CancelTask.searchApi
    guard cancellables[id] == nil else { return }
    run(id: id) {
      let stream = textStream
        .debounce(for: 1, scheduler: DispatchQueue.main)
        .stream
      
      for await query in stream {
        searchApi(query)
      }
    }
  }
  
  private func searchApi(_ query: String) {
    run {
      var result = try await worker.search(request: .init(query: query))
      try Task.checkCancellation()
      result.coins = Array(result.coins.prefix(5))
      result.nfts = Array(result.nfts.prefix(5))
      result.exchanges = Array(result.exchanges.prefix(5))
      searchResults = result
      try saveRecentSearch()
      await presenter?.updateList(.search(result))
    } errorHandler: { error in
      await presenter?.presentAlert(message: error.localizedDescription)
    }
  }
  
  private func saveRecentSearch() throws {
    guard let searchData else { return }
    try Task.checkCancellation()
    try worker.saveSearchHistory(searchData)
    if recentSearches.firstIndex(of: searchData) == nil {
      recentSearches.append(searchData)
      if recentSearches.count > 3 {
        recentSearches.removeFirst()
      }
    }
  }
  
  private func cancelSearchApiTask() {
    let id = CancelTask.searchApi
    cancellables[id]?.cancel()
    cancellables[id] = nil
    searchResults = nil
    run { await presenter?.updateList(updateListResponse) }
  }
  
  public func categoryTapped(_ request: SearchFeature.CategoryTapped.Request) {
    let section = sectionList[request.indexPath.section]
    switch section {
    case .trending:
      selectedTrendingCategory = .init(rawValue: request.indexPath.row) ?? selectedTrendingCategory
      updateTrendingSection()
    case .highlight:
      selectedHighlightCategory = .init(rawValue: request.indexPath.row) ?? selectedHighlightCategory
      run { await presenter?.updateSection(.highlight(updateHighlight)) }
    default:
      break
    }
  }
  
  public func tappedExpandRow() {
    isTrendingExpanded = true
    updateTrendingSection()
  }
  
  private func updateTrendingSection() {
    run { await presenter?.updateSection(.trending(updateTrending)) }
  }
}

private extension SearchInteractor {
  // MARK: - Cancel Task ID
  enum CancelTask: Hashable {
    case searchApi
  }
  
  var updateListResponse: SearchFeature.UpdateList.Response {
    .information(
      .init(
        recentSearchs: recentSearches,
        trending: updateTrending,
        highlight: updateHighlight
      )
    )
  }
  
  var updateTrending: SearchFeature.UpdateList.Response.Information.Trending {
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
  
  var updateHighlight: SearchFeature.UpdateList.Response.Information.Highlight {
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
  
  var searchData: SearchFeature.SearchApi.Response.Item? {
    guard let searchResults else { return nil }
    if let coin = searchResults.coins.first {
      return coin
    }
    if let nft = searchResults.nfts.first {
      return nft
    }
    if let exchange = searchResults.exchanges.first {
      return exchange
    }
    return nil
  }
}
