import UIKit

public protocol SearchRoutingLogic {
  func presentAlert(message: String)
}

public final class SearchRouter: SearchRoutingLogic {
  weak var viewController: UIViewController?
  
  public func presentAlert(message: String) {
    let alert = UIAlertController(
      title: "서버 오류",
      message: message,
      preferredStyle: .alert
    )
    alert.addAction(.init(title: "확인", style: .cancel))
    viewController?.present(alert, animated: true)
  }
}
