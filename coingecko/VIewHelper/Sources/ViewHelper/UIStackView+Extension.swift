import class UIKit.NSLayoutConstraint
import class UIKit.UIStackView
import struct UIKit.CGFloat
import class UIKit.UIView

public extension UIStackView {
  convenience init(
    _ axis: NSLayoutConstraint.Axis = .vertical,
    alignment: Alignment = .center,
    spacing: CGFloat = 0,
    subviews: [UIView] = []
  ) {
    self.init(arrangedSubviews: subviews)
    self.alignment = alignment
    self.axis = axis
    self.spacing = spacing
  }
}

public extension UIStackView {
  func addArrangedSubviews(_ views: [UIView]) {
    views.forEach(addArrangedSubview)
  }
  
  func addSpacing(_ value: CGFloat? = nil) {
    let spacing = UIView()
    if let value {
      switch axis {
      case .vertical:
        spacing.heightAnchor.constraint(equalToConstant: value).isActive = true
      case .horizontal:
        spacing.widthAnchor.constraint(equalToConstant: value).isActive = true
      @unknown default:
        break
      }
    }
    addArrangedSubview(spacing)
  }
}
