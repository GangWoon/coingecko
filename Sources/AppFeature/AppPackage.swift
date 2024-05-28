import SearchFeatureView
import SearchFeature
import UIKit

public class AppDelegate: NSObject, UIApplicationDelegate {
  public var window: UIWindow?
  
  public func applicationDidFinishLaunching(_ application: UIApplication) {
    window = .init()
    let vc = UIViewController()
    vc.view.backgroundColor = .green
    window?.rootViewController = build()
    window?.makeKeyAndVisible()
  }
  
  func build() -> UIViewController {
    let interactor = SearchInteractor()
    let presenter = SearchPresenter()
    interactor.presenter = presenter
    interactor.worker = SearchWorker()
    let vc = SearchViewController(interactor: interactor)
    presenter.viewController = vc
    
    return vc
  }
}
