import ViewHelper
import UIKit

final public class CoinView: UIView {
  private let state: State
  
  public init(state: State) {
    self.state = state
    super.init(frame: .zero)
    build()
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func build() {
    let imageView = AsyncUIImageView(
      url: state.imageUrl,
      placeholder: UIImage(systemName: "list.bullet")?
        .withRenderingMode(.alwaysTemplate)
    )
    imageView.tintColor = .black
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalToConstant: 20),
      imageView.heightAnchor.constraint(equalToConstant: 20)
    ])
    
    let label = UILabel()
    label.font = .systemFont(ofSize: 14, weight: .bold)
    label.text = state.abbreviation
    
    let fullnameLabel = UILabel()
    fullnameLabel.font = .systemFont(ofSize: 12, weight: .light)
    fullnameLabel.textColor = .gray
    fullnameLabel.text = state.fullname
    
    let vStack = UIStackView(arrangedSubviews: [label, fullnameLabel])
    vStack.axis = .vertical
    vStack.alignment = .top
    
    let stack = UIStackView(arrangedSubviews: [imageView, vStack])
    stack.spacing = 6
    addSubview(stack)
    stack.equalToParent()
    stack.alignment = .center
  }
}


extension CoinView {
  public struct State: Equatable {
    let imageUrl: URL?
    let abbreviation: String
    let fullname: String
    
    public init(
      imageUrl: URL?,
      abbreviation: String,
      fullname: String
    ) {
      self.imageUrl = imageUrl
      self.abbreviation = abbreviation
      self.fullname = fullname
    }
  }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
  let view = CoinView(
    state: .init(imageUrl: .init(string: ""), abbreviation: "ETH", fullname: "이더리움")
  )
  
  return view
}
#endif
