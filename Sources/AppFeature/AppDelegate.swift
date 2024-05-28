import SearchFeatureView
import UIKit

public class AppDelegate: NSObject, UIApplicationDelegate {
  public var window: UIWindow?
  
  public func applicationDidFinishLaunching(_ application: UIApplication) {
    window = .init()
    window?.rootViewController = SearchSceneBuilder(dependency: .live).build()
    window?.makeKeyAndVisible()
  }
}
