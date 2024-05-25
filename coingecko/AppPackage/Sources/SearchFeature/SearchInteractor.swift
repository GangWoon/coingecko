import Foundation

public protocol SearchDataStore {
  var text: String { get }
  var sectionList: [SearchFeature.ViewModel.SectionType] { get }
  var selectedTrendingCategory: SearchFeature.TrendingCategory { get set }
  
  var trendingCategory: [SearchFeature.TrendingCategory] { get }
  var highlightCategory: [SearchFeature.HighlightCategory] { get }
}

public protocol SearchBusinessLogic {
  func searchFieldChanged(_ text: String?)
  func categoryTapped(_ request: SearchFeature.CategoryTapped.Request)
  func viewWillAppear(_ request: SearchFeature.ViewWillAppear.Reqeuset)
  func viewDidDisAppear()
}

public final class SearchInteractor: SearchDataStore {
  public var sectionList: [SearchFeature.ViewModel.SectionType] {
    Array(dataSource.keys.sorted())
  }
  public var trendingCategory: [SearchFeature.TrendingCategory] {
    Array(trendingDataSource.state.keys.sorted())
  }
  public var highlightCategory: [SearchFeature.HighlightCategory] = [.topGainers, .topLosers, .newListings]
  public var dataSource: [SearchFeature.ViewModel.SectionType : [SearchFeature.RowData]] = [:]
  
  // MARK: - State
  public var text: String = ""
  
  public var selectedTrendingCategory: SearchFeature.TrendingCategory = .coin
  public var trendingDataSource: SearchFeature.FetchTrending.Response = .empty
  public var selectedHighlightCategory: SearchFeature.HighlightCategory = .topGainers
  public var highlightDataSource: SearchFeature.FetchHighlight.Response = .empty
  
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
      dataSource[.trending] = trendingDataSource.state[.init(rawValue: request.indexPath.row) ?? .coin]
      Task { @MainActor in
        presenter?.applySnapshot(items: dataSource)
      }
    case .highlight:
      selectedHighlightCategory = SearchFeature.HighlightCategory(rawValue: request.indexPath.row) ?? selectedHighlightCategory
      switch selectedHighlightCategory {
      case .topGainers:
        dataSource[.highlight] = highlightDataSource.topGainer
      case .topLosers:
        dataSource[.highlight] = highlightDataSource.topLoser
      case .newListings:
        dataSource[.highlight] = highlightDataSource.newCoins
      }
      Task { @MainActor in
        presenter?.applySnapshot(items: dataSource)
      }
    }
  }
  
  public func viewWillAppear(_ request: SearchFeature.ViewWillAppear.Reqeuset) {
    Task {
      if !worker.loadSearchHistory().isEmpty {
        dataSource[.history] = []
        // MARK: - LoadFromDisk
      }
      do {
        trendingDataSource = try await worker.getTrending()
        dataSource[.trending] = trendingDataSource.state[selectedTrendingCategory]
        highlightDataSource = try await worker.getHighlight()
        
        switch selectedHighlightCategory {
        case .topGainers:
          dataSource[.highlight] = highlightDataSource.topGainer
        case .topLosers:
          dataSource[.highlight] = highlightDataSource.topLoser
        case .newListings:
          dataSource[.highlight] = highlightDataSource.newCoins
        }
        
        await presenter?.applySnapshot(items: dataSource)
      } catch {
        print(error)
      }
    }
  }
  
  public func viewDidDisAppear() { }
}
