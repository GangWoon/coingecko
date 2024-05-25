import class UIKit.UIView

public protocol ReusableIdentifier: AnyObject {
  static var identifier: String { get }
}

extension ReusableIdentifier where Self: UIView {
  public static var identifier: String {
    String(describing: self)
  }
}
