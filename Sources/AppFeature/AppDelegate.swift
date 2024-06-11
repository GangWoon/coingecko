import SearchFeatureView
import SearchFeature
import UIKit

public final class AppDelegate: NSObject, UIApplicationDelegate {
  public var window: UIWindow?
  
  public func applicationDidFinishLaunching(_ application: UIApplication) {
    window = .init()
    window?.rootViewController = buildRootViewController()
    window?.makeKeyAndVisible()
  }
  
  private func buildRootViewController() -> UIViewController {
    /// SearchSceneBuilder(dependency:) 파라미터로
    /// .live, .preview, .error으로 설정해서 여러가지 상황에 대해서 테스트 할 수 있습니다.
    let builder = SearchSceneBuilder(dependency: .live)
    return builder.build()
  }
}
