import SearchFeature

public struct SearchSceneBuilder {
  public init() { }

  public func build() -> SearchViewController {
    let worker = SearchWorker(apiClient: .live)
    let interactor = SearchInteractor(worker: worker)
    let viewController = SearchViewController(interactor: interactor)
    let presenter = SearchPresenter(viewController: viewController)
    interactor.presenter = presenter
    
    return viewController
  }
}
