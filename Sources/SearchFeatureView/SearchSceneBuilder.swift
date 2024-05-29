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
  
  public init(dependency: Dependency) {
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
  static let live = Self(
    work: SearchWorker(apiClient: .live)
  )
}
