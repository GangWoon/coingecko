import class UIKit.UITableViewHeaderFooterView
import class UIKit.UITableViewCell
import class UIKit.UITableView
import struct UIKit.IndexPath

extension UITableViewCell: ReusableIdentifier { }

public extension UITableView {
  func register<T: ReusableIdentifier>(type: T.Type) {
    register(type, forCellReuseIdentifier: type.identifier)
  }
  
  func dequeueReusableCell<T: ReusableIdentifier>(
    type: T.Type,
    for indexPath: IndexPath
  ) -> T? {
    guard
      let cell = dequeueReusableCell(withIdentifier: T.identifier, for: indexPath) as? T
    else { return nil }
    return cell
  }
}

extension UITableViewHeaderFooterView: ReusableIdentifier { }
public extension UITableView {
  func registerForHeaderFooterView<T: ReusableIdentifier>(type: T.Type) {
    self.register(type, forHeaderFooterViewReuseIdentifier: type.identifier)
  }
  
  func dequeueReusableHeaderFooterView<T: ReusableIdentifier>(type: T.Type) -> T? {
    guard
      let view = dequeueReusableHeaderFooterView(withIdentifier: type.identifier) as? T
    else { return nil }
    return view
  }
}
