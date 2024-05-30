import struct UIKit.IndexPath
import Foundation
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
  
  // MARK: - Interface
  public var worker: any SearchWorkerInterface
  public var presenter: (any SearchPresentationLogic)?
  /// var navigate: (model) -> Void
  
  /// 글로벌 변수로 뺄 수 있을 거 같아보입니다.
  private var cancellables: [AnyHashable: Task<Void, Never>] = [:]
  
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
    
    self.worker = worker
  }
  
  @discardableResult
  private func run(_ work: @MainActor @Sendable @escaping () async -> Void) -> Task<Void, Never> {
    let id = UUID()
    let task = Task {
      defer { cancellables[id] = nil }
      await work()
    }
    cancellables[id] = task
    
    return task
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
      newCoins: [SearchFeature.Coin] = [],
      searchResults: SearchFeature.SearchApi.Response? = nil
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
      self.searchResults = searchResults
    }
  }
}

// MARK: - BusinessLogic
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
    let id: AnyHashable = CancelTask.searchApi
    if let text, !text.isEmpty {
      self.text = text
      isLoading = true
      run { [weak self] in
        guard let self else { return }
        self.presenter?.updateList(.loading)
      }
      if cancellables[id] == nil {
        let task = Task {
          do {
            try await convertTask(
              textStream
                .debounce(for: 1, scheduler: DispatchQueue.main)
                .sink { [weak self] in
                  self?.searchApi($0)
                }
            )
          } catch { }
        }
        cancellables[id] = task
      }
      textStream.send(text)
    } else {
      cancellables[id]?.cancel()
      cancellables[id] = nil
      searchResults = nil
      run { [weak self] in
        guard let self else { return }
        self.presenter?.updateList(updateListResponse)
      }
    }
  }
  
  private func searchApi(_ query: String) {
    let id = UUID()
    let task = Task {
      defer { cancellables[id] = nil }
      do {
        var result = try await worker.search(request: .init(query: query))
        result.coins = Array(result.coins.prefix(5))
        result.nfts = Array(result.nfts.prefix(5))
        result.exchanges = Array(result.exchanges.prefix(5))
        searchResults = result
        
        await presenter?.updateList(.search(result))
      } catch is CancellationError {
      } catch {
        print(error)
      }
    }
    cancellables[id] = task
  }
  
  public func categoryTapped(_ request: SearchFeature.CategoryTapped.Request) {
    let section = sectionList[request.indexPath.section]
    switch section {
    case .trending:
      selectedTrendingCategory = SearchFeature.TrendingCategory(rawValue: request.indexPath.row) ?? selectedTrendingCategory
      updateTrendingSection()
    case .highlight:
      selectedHighlightCategory = SearchFeature.HighlightCategory(rawValue: request.indexPath.row) ?? selectedHighlightCategory
      run { [weak self] in
        guard let self else { return }
        self.presenter?.updateSection(.highlight(self.updateHighlight))
      }
    default:
      break
    }
  }
  
  public func tappedExpandRow() {
    isTrendingExpanded = true
    updateTrendingSection()
  }
  
  private func updateTrendingSection() {
    run { [weak self] in
      guard let self else { return }
      self.presenter?.updateSection(.trending(self.updateTrending))
    }
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

private func convertTask(
  _ subscription: AnyCancellable
) async throws {
  let box = SubscriptionBox()
  final class SubscriptionBox {
    var subscription: AnyCancellable?
    func cancel() {
      subscription?.cancel()
      subscription = nil
    }
  }
  let stream: AsyncStream<Void> = .init { continuation in
    box.subscription = subscription
    continuation.onTermination = { _ in
      box.cancel()
    }
  }
  
  try await withTaskCancellationHandler(
    operation: {
      for await _ in stream {
        try await Task.sleep(nanoseconds: 1_000_000_000)
      }
    },
    onCancel: {
      box.cancel()
    }
  )
}
