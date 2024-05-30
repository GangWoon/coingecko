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
  
  // MARK: - Interface
  public var worker: any SearchWorkerInterface
  public var presenter: (any SearchPresentationLogic)?
  /// var navigate: (model) -> Void
  
  /// 글로벌 변수로 뺄 수 있을 거 같아보입니다.
  private var cancellables: [UUID: Task<Void, Never>] = [:]
  private var removableCancellations: [UUID] = []
  
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
    
    subscibeStream()
  }
  
  deinit {
    removableCancellations
      .forEach {
        cancellables[$0]?.cancel()
        cancellables[$0] = nil
      }
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
  
  private func subscibeStream() {
    subscribeTextStream()
  }
  
  private func subscribeTextStream() {
    let id = UUID()
    let task = convertTask(
      textStream
        .debounce(for: 1, scheduler: DispatchQueue.main)
        .sink { [weak self] in
          self?.searchApi($0)
        }
    )
    cancellables[id] = task
    removableCancellations.append(id)
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
      run { [weak self] in
        guard let self else { return }
        self.presenter?.updateSection(.trending(self.updateTrending))
      }
    case .highlight:
      selectedHighlightCategory = SearchFeature.HighlightCategory(rawValue: request.indexPath.row) ?? selectedHighlightCategory
      updateTrendingSection()
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

private func convertTask(_ subscription: AnyCancellable) -> Task<Void, Never> {
  let box = SubscriptionBox()
  final class SubscriptionBox {
    var subscription: AnyCancellable?
    func cancel() {
      subscription?.cancel()
      subscription = nil
    }
  }
  
  return Task {
    let stream = AsyncStream(
      unfolding: { box.subscription = subscription },
      onCancel: { box.cancel() }
    )
  }
}
