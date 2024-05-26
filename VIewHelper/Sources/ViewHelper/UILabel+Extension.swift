import class UIKit.UILabel
import class UIKit.UIColor
import class UIKit.UIFont

public extension UILabel {
  convenience init(
    text: String?,
    textColor: UIColor = .black,
    font: UIFont = .systemFont(ofSize: 14)
  ) {
    self.init()
    self.text = text
    self.textColor = textColor
    self.font = font
  }
}
