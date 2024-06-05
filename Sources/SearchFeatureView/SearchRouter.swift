import UIKit

public protocol SearchRoutingLogic {
  func presentAlert(message: String)
}

public final class SearchRouter: SearchRoutingLogic {
  weak var viewController: UIViewController?
  var errorViewController: (String) -> UIViewController?
  
  public init(errorViewController: @escaping (String) -> UIViewController?) {
    self.errorViewController = errorViewController
  }
  
  public func presentAlert(message: String) {
    guard let alert = errorViewController(message) else { return }
    viewController?.present(alert, animated: true)
  }
}

public final class AlertRouter {
  static let live = AlertRouter()
  func presentErrorAlert(message: String) -> UIViewController {
    let alert = UIAlertController(
      title: "서버 오류",
      message: message,
      preferredStyle: .alert
    )
    alert.addAction(.init(title: "확인", style: .cancel))
    
    return alert
  }
}
