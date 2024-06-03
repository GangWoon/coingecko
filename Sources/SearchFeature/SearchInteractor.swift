import struct UIKit.IndexPath
import Foundation
import CombineExt
import Combine

// MARK: - Read in View
/// 해당 프로토콜은 상태값을 표현하는 역활이 아닌, 상태값을 변경 시켜주는 "object"여야 합니다.
/// 단발성 상태값을 표현하는 프로토콜이기 때문에 초기값으로 세팅하는 걸 확인하는 상황이 아니라면 존재에 이유가 궁금해집니다.
/// 반대로 BusinessLogic value, reference의 의존하지 않는 객체이기 때문에 추가적인 혼란이 발생합니다.
/// 결국 Interactor라는 객체는 이 둘의 조합을 이루어서 엑션을 받았을 때 상태값을 갱신함으로 써 외부로 새로운 상태값을 노출시키는게 포인트라고 생각합니다.
/// 분리해서 이득이 되는 경우가 궁금합니다.
public protocol SearchDataStore: AnyObject {
  var text: String { get }
  var isLoading: Bool { get }
  var sectionList: [SearchFeature.SectionType] { get }
  var selectedTrendingCategory: SearchFeature.TrendingCategory { get }
  var selectedHighlightCategory: SearchFeature.HighlightCategory { get }
}

// MARK: - Read in View
public protocol SearchBusinessLogic {
  func prepare() async
  
  func searchFieldChanged(_ text: String?)
  func categoryTapped(_ request: SearchFeature.CategoryTapped.Request)
  func tappedExpandRow()
}

public final class SearchInteractor: SearchDataStore {
  public var destination: SearchFeature.Destination?
  public var text: String
  private var textStream = PassthroughSubject<String, Never>()
  
  public var isTrendingExpanded: Bool
  public var selectedTrendingCategory: SearchFeature.TrendingCategory
  public var trendingCoins: [SearchFeature.Coin]
  public var trendingNFTs: [SearchFeature.NFT]
  public var trendingCategories: [SearchFeature.Category]
  
  public var selectedHighlightCategory: SearchFeature.HighlightCategory
  public var topGainer: [SearchFeature.Coin]
  public var topLoser: [SearchFeature.Coin]
  public var newCoins: [SearchFeature.Coin]
  
  public var isLoading: Bool = false
  public var searchResults: SearchFeature.SearchApi.Response?
  public var recentSearches: [SearchFeature.SearchApi.Response.Item]
  
  // MARK: - Interface
  public var worker: any SearchWorkerInterface
  public var presenter: (any SearchPresentationLogic)?
  /// var navigate: (model) -> Void
  
  private var cancellables: [AnyHashable: Task<Void, Never>] = [:]
  private var _lock: NSLock = .init()
  
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
    self.searchResults = state.searchResults
    self.recentSearches = state.recentSearches
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
  public var sectionList: [SearchFeature.SectionType] {
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
        list.append(.trending)
      }
      if hasHighlightData {
        list.append(.highlight)
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
    public var destination: SearchFeature.Destination?
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
    public var searchResults: SearchFeature.SearchApi.Response?
    public var recentSearches: [SearchFeature.SearchApi.Response.Item]
    
    public init(
      destination: SearchFeature.Destination? = nil,
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
      newCoins: [SearchFeature.Coin] = [],
      searchResults: SearchFeature.SearchApi.Response? = nil,
      recentSearches: [SearchFeature.SearchApi.Response.Item] = []
    ) {
      self.destination = destination
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
      self.searchResults = searchResults
      self.recentSearches = recentSearches
    }
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
      let destination: SearchFeature.Destination = .alert(message: error.localizedDescription)
      self.destination = destination
      await presenter?.changeDestination(destination)
    }
  }
  
  public func searchFieldChanged(_ text: String?) {
    guard
      let text, !text.isEmpty
    else {
      cancelSearchApiTask()
      return
    }
    self.text = text
    isLoading = true
    buildTextStream()
    textStream.send(text)
    run { await presenter?.updateList(.loading) }
  }
  
  private func buildTextStream() {
    let id: AnyHashable = CancelTask.searchApi
    guard cancellables[id] == nil else { return }
    run(id: id) {
      try await textStream
        .debounce(for: 1, scheduler: DispatchQueue.main)
        .sink { [weak self] in
          self?.searchApi($0)
        }
        .stream
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
      let destination: SearchFeature.Destination = .alert(message: error.localizedDescription)
      self.destination = destination
      await presenter?.changeDestination(destination)
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
