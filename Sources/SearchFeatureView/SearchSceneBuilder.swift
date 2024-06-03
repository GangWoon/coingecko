import RecentSearchesClientLive
import ApiClientLive
import SearchFeature

public struct SearchSceneBuilder {
  let dependency: Dependency
  public struct Dependency {
    let worker: SearchWorkerInterface
    ///  Maybe insert Navigator
    ///  navigate: (model) -> Void
    public init(work: SearchWorkerInterface) {
      self.worker = work
    }
  }
  
  public init(dependency: Dependency = .live) {
    self.dependency = dependency
  }
  
  public func build() -> SearchViewController {
    let interactor = SearchInteractor(worker: dependency.worker)
    let viewController = SearchViewController(interactor: interactor)
    let presenter = SearchPresenter(viewController: viewController)
    interactor.presenter = presenter
    
    return viewController
  }
}

public extension SearchSceneBuilder.Dependency {
  static let live: Self = {
    return .init(
      work: SearchWorker(
        apiClient: .live,
        recentSearchesClient: .sqlite()
      )
    )
  }()
  
  static let preview = Self(
    work: SearchWorker(
      apiClient: .preview,
      recentSearchesClient: .preview(
        [
          .init(symbol: "XDC", name: "XDC Network", thumbnail: "https://coin-images.coingecko.com/coins/images/2912/thumb/xdc-icon.png"),
          .init(symbol: "BTC", name: "비트코인", thumbnail: "https://coin-images.coingecko.com/coins/images/1/thumb/bitcoin.png")
        ]
      )
    )
  )
  
  static let error = Self(
    work: SearchWorker(
      apiClient: .error,
      recentSearchesClient: .error
    )
  )
}
