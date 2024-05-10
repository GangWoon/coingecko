import class UIKit.NSLayoutConstraint
import class UIKit.UIStackView
import struct UIKit.CGFloat
import class UIKit.UIView

// MARK: - AutoLayout
public extension UIView {
  func equalToParent() {
    translatesAutoresizingMaskIntoConstraints = false
    if let superview {
      NSLayoutConstraint.activate([
        topAnchor.constraint(equalTo: superview.topAnchor),
        leadingAnchor.constraint(equalTo: superview.leadingAnchor),
        trailingAnchor.constraint(equalTo: superview.trailingAnchor),
        bottomAnchor.constraint(equalTo: superview.bottomAnchor)
      ])
    }
  }
}

// MARK: - Padding
public extension UIView {
  func addPadding(_ value: CGFloat = 8) -> UIView {
    let stack = UIStackView(arrangedSubviews: [self])
    stack.isLayoutMarginsRelativeArrangement = true
    stack.directionalLayoutMargins = .init(top: value, leading: value, bottom: value, trailing: value)
    
    return stack
  }
  
  func addPadding(
    top: CGFloat = 0,
    leading: CGFloat = 0,
    bottom:CGFloat = 0,
    trailing: CGFloat = 0
  ) -> UIView {
    let stack = UIStackView(arrangedSubviews: [self])
    stack.isLayoutMarginsRelativeArrangement = true
    stack.directionalLayoutMargins = .init(top: top, leading: leading, bottom: bottom, trailing: trailing)
    
    return stack
  }
  
  static func spacing() -> UIView {
    return UIView()
  }
}
