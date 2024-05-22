import ViewHelper
import UIKit

protocol ViewStateRemover {
  var viewStateRemover: [() -> ()?] { get set }
  func removeState()
}

extension ViewStateRemover {
  func removeState() {
    viewStateRemover
      .forEach { $0() }
  }
}

final class SearchListRow: UITableViewCell, ViewStateRemover {
  var viewStateRemover: [() -> ()?] = []
  
  override func prepareForReuse() {
    super.prepareForReuse()
    removeState()
  }
  
  func build(type: SearchFeature.ViewModel.SectionType, state: State) {
    let stack = UIStackView()
    stack.isLayoutMarginsRelativeArrangement = true
    stack.directionalLayoutMargins = .searchListRow
    switch type {
    case .history:
      buildPrimaryStyle(stack, state: state)
    default:
      buildSecondaryStyle(stack, state: state)
    }
    contentView.addSubview(stack)
    stack.equalToParent()
    
    let remover = { [weak stack] in
      stack?.removeFromSuperview()
    }
    viewStateRemover.append(remover)
  }
  
  private func buildPrimaryStyle(_ stack: UIStackView, state: State) {
    let coinView = CoinView(state: state.coinState)
    let label = UILabel(
      text: "#\(state.rank)",
      textColor: .gray,
      font: .systemFont(ofSize: 12, weight: .light)
    )
    stack.addArrangedSubviews([coinView, .spacing(), label])
  }
  
  private func buildSecondaryStyle(_ stack: UIStackView, state: State) {
    let label = UILabel(
      text: "\(state.rank)",
      textColor: .gray,
      font: .systemFont(ofSize: 12, weight: .light)
    )
    stack.addArrangedSubview(label)
    label.widthAnchor.constraint(equalToConstant: 22).isActive = true
    
    stack.addSpacing(12)
    
    let coinView = CoinView(state: state.coinState)
    stack.addArrangedSubview(coinView)
    
    if let priceInfo = state.priceInfo {
      stack.addSpacing()
      buildSecondaryAccessoryView(stack, priceInfo: priceInfo)
    }
  }
  
  private func buildSecondaryAccessoryView(_ stack: UIStackView, priceInfo: State.PriceInfo) {
    let currentPriceLabel = UILabel(
      text: "￦\(priceInfo.current)",
      textColor: .black,
      font: .systemFont(ofSize: 14, weight: .light)
    )
    
    let imageConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 12, weight: .medium))
    let image = UIImage(systemName: "arrow.up", withConfiguration: imageConfiguration)
    let imageView = UIImageView(image: image)
    imageView.contentMode = .scaleAspectFit
    
    let changeLabel = UILabel(
      text: "\(priceInfo.change24h)%",
      textColor: .black,
      font: .systemFont(ofSize: 12, weight: .medium)
    )
    
    let hStack = UIStackView(
      .horizontal,
      spacing: 4,
      subviews: [imageView, changeLabel]
    )
    let vStack = UIStackView(subviews: [currentPriceLabel, hStack])
    
    stack.addArrangedSubview(vStack)
  }
}

extension SearchListRow {
  struct State {
    let rank: String
    let imageUrl: URL?
    let abbreviation: String
    let fullname: String
    let priceInfo: PriceInfo?
    struct PriceInfo: Equatable {
      let current: Double
      let change24h: Double
    }
  }
}

extension SearchListRow.State {
  var coinState: CoinView.State {
    .init(
      imageUrl: imageUrl,
      abbreviation: abbreviation,
      fullname: fullname
    )
  }
}

extension NSDirectionalEdgeInsets {
  fileprivate static let searchListRow = Self(top: 8, leading: 16, bottom: 8, trailing: 16)
}



