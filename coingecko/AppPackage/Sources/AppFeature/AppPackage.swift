import UIKit

public class AppDelegate: NSObject, UIApplicationDelegate {
  public var window: UIWindow?
  
  public func applicationDidFinishLaunching(_ application: UIApplication) {
    window = .init()
    let vc = UIViewController()
    vc.view.backgroundColor = .green
    window?.rootViewController = vc
    window?.makeKeyAndVisible()
  }
}
