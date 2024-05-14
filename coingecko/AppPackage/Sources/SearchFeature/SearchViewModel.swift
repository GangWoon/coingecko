import Foundation
import Combine

public final class SearchViewModel {
  public var state: CurrentValueSubject<State, Never>
  public var environment: Environment
  private var cancellables: Set<AnyCancellable> = []
  
  public init(
    state: State = .empty,
    enviornment: Environment
  ) {
    self.state = .init(state)
    self.environment = enviornment
  }
  
  func send(_ action: Action) {
    switch action {
    case let .searchFieldChanged(text):
      state.value.searchQuery = text ?? ""
      
    case .viewWillAppear:
      let searchHistory = environment.loadSearchHistory()
      if !searchHistory.isEmpty {
        state.value.listItem.append(contentsOf: [])
      }
      // TODO: - Fetch Trending Data
      // TODO: - Fetch Highlight Data
    }
  }
}

extension SearchViewModel {
  public struct State: Equatable {
    public static let empty = State()
    var searchQuery: String
    var listItem: [ListType]
    public enum ListType: Equatable {
      case searchHistory(Item)
      case trending(Item)
      case highlight(Item)
      
      public struct Item: Equatable {
        let rank: Int
        let name: String
        let fullname: String
        let priceInfo: PriceInfo?
        struct PriceInfo: Equatable {
          let current: Double
          let changed24h: Double
        }
      }
    }
    
    public init(
      searchQuery: String = "",
      listItem: [ListType] = []
    ) {
      self.searchQuery = searchQuery
      self.listItem = listItem
    }
  }
  
  enum Action: Equatable {
    case searchFieldChanged(String?)
    case viewWillAppear
  }
  
  public struct Environment {
    var loadSearchHistory: () -> [String]
    var saveSearchHistory: () -> Void
    
    public init(
      loadSearchHistory: @escaping () -> [String],
      saveSearchHistory: @escaping () -> Void
    ) {
      self.loadSearchHistory = loadSearchHistory
      self.saveSearchHistory = saveSearchHistory
    }
  }
}
