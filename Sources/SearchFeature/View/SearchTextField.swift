import UIKit

public final class SearchTextField: UITextField {
  public override init(frame: CGRect) {
    super.init(frame: frame)
    build()
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func textRect(forBounds bounds: CGRect) -> CGRect {
    let rect = super.textRect(forBounds: bounds)
    
    return buildLeftImageMargin(rect)
  }
  
  public override func editingRect(forBounds bounds: CGRect) -> CGRect {
    let rect = super.textRect(forBounds: bounds)
    
    return buildLeftImageMargin(rect)
  }
  
  private func buildLeftImageMargin(_ bounds: CGRect) -> CGRect {
    var insets = UIEdgeInsets.zero
    insets.left = 8
    
    return bounds.inset(by: insets)
  }
  
  public override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
    var rect = super.leftViewRect(forBounds: bounds)
    rect.origin.x = 16
    
    return rect
  }
  
  private func build() {
    layer.borderWidth = 2
    layer.borderColor = UIColor.gray.cgColor
    layer.cornerRadius = 16
    
    let searchImage = UIImage(systemName: "magnifyingglass")?
      .withTintColor(.gray, renderingMode: .alwaysOriginal)
    backgroundColor = .white
    leftView = UIImageView(image: searchImage)
    leftViewMode = .always
  }
}
