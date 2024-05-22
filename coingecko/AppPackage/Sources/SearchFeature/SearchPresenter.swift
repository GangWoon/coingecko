import Foundation

public protocol SearchPresentationLogic: AnyObject {
  func applySnapshot(items: [SearchFeature.ViewModel.SectionType : [SearchFeature.RowData]])
}

public final class SearchPresenter {
  public weak var viewController: SearchDisplayLogic?
  
  public init(viewController: SearchDisplayLogic? = nil) {
    self.viewController = viewController
  }
}

extension SearchPresenter: SearchPresentationLogic {
  public func applySnapshot(items: [SearchFeature.ViewModel.SectionType : [SearchFeature.RowData]]) {
    viewController?.applySnapshot(items: items)
  }
}
