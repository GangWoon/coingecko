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
    Array(dataSource.keys)
  }
  public var trendingCategory: [SearchFeature.TrendingCategory] {
    Array(trendingDataSource.state.keys)
  }
  public var highlightCategory: [SearchFeature.HighlightCategory] = [.topGainers, .topLosers, .newListings]
  public var dataSource: [SearchFeature.ViewModel.SectionType : [SearchFeature.RowData]] = [:]
  
  // MARK: - State
  public var text: String = ""
  
  public var selectedTrendingCategory: SearchFeature.TrendingCategory = .coin
  public var trendingDataSource: SearchFeature.FetchTrending.Response = .init(state: [:])
  
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
    case .trending:
      dataSource[.trending] = trendingDataSource.state[.init(rawValue: request.indexPath.row) ?? .coin]
      presenter?.applySnapshot(items: dataSource)
    default:
      break
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
        
        /// fetch hightlight
        presenter?.applySnapshot(items: dataSource)
      } catch {
        print(error)
      }
    }
  }
  
  public func viewDidDisAppear() { }
}

public enum TrendingCategory {
  case coin
  case nft
  case category
}
