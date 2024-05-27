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
  
  func build(_ viewType: ViewType, state: State) {
    selectionStyle = .none
    let stack = UIStackView()
    stack.isLayoutMarginsRelativeArrangement = true
    stack.directionalLayoutMargins = .searchListRow
    switch viewType {
    case .primary:
      buildPrimaryStyle(stack, state: state)
    case .secondary:
      buildSecondaryStyle(stack, viewType: viewType, state: state)
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
    viewStateRemover.append({ [weak coinView] in
      coinView?.removeState()
    })
    if let rank = state.rank {
      let label = UILabel(
        text: "#\(rank)",
        textColor: .gray,
        font: .systemFont(ofSize: 12, weight: .light)
      )
      stack.addArrangedSubviews([coinView, .spacing(), label])
    } else {
      if let priceInfo = state.priceInfo {
        let priceView = buildChangePriceView(priceInfo: priceInfo)
        stack.addArrangedSubviews([coinView, .spacing(), priceView])
      }
    }
  }
  
  private func buildSecondaryStyle(
    _ stack: UIStackView,
    viewType: ViewType,
    state: State
  ) {
    guard 
      case .secondary(hasRank: let hasRank) = viewType
    else { return }
    if hasRank {
      let label = UILabel(
        text: state.rank,
        textColor: .gray,
        font: .systemFont(ofSize: 10, weight: .light)
      )
      stack.addArrangedSubview(label)
      label.widthAnchor.constraint(equalToConstant: 22).isActive = true
      stack.addSpacing(12)
    }
    
    let coinView = CoinView(state: state.coinState)
    viewStateRemover.append({ [weak coinView] in
      coinView?.removeState()
    })
    stack.addArrangedSubview(coinView)
    
    if let priceInfo = state.priceInfo {
      stack.addSpacing()
      buildPriceStack(stack, priceInfo: priceInfo)
    }
  }
  
  private func buildPriceStack(_ stack: UIStackView, priceInfo: State.PriceInfo) {
    let currentPriceLabel = UILabel(
      text: "￦\(priceInfo.current)",
      textColor: .black,
      font: .boldSystemFont(ofSize: 14)
    )
    let priceView = buildChangePriceView(priceInfo: priceInfo)
    
    let vStack = UIStackView(subviews: [currentPriceLabel, priceView])
    vStack.alignment = .trailing
    
    stack.addArrangedSubview(vStack)
  }
  
  private func buildChangePriceView(priceInfo: State.PriceInfo) -> UIView {
    let imageConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 12, weight: .medium))
    let flag = priceInfo.change24h > 0
    let imageName = flag ? "arrow.up" : "arrow.down"
    let image = UIImage(systemName: imageName, withConfiguration: imageConfiguration)?
      .withRenderingMode(.alwaysTemplate)
    let imageView = UIImageView(image: image)
    imageView.tintColor = flag ? .systemGreen : .systemRed
    imageView.contentMode = .scaleAspectFit
    
    let changeLabel = UILabel(
      text: priceInfo.change24hText,
      textColor: flag ? .systemGreen : .systemRed,
      font: .systemFont(ofSize: 12, weight: .medium)
    )
    
    let stack = UIStackView(
      .horizontal,
      spacing: 4,
      subviews: [imageView, changeLabel]
    )
    
    return stack
  }
  
  func buildExpandView(_ state: State, action: UIAction) {
    var configuration = UIButton.Configuration.plain()
    configuration.title = state.fullname
    configuration.titleAlignment = .center
    configuration.baseForegroundColor = .systemGray
    
    let button = UIButton(configuration: configuration, primaryAction: action)
    viewStateRemover.append { [weak button] in
      button?.removeFromSuperview()
    }
    button.titleLabel?.font = .systemFont(ofSize: 14, weight: .light)
    contentView.addSubview(button)
    button.equalToParent()
  }
}

extension SearchListRow {
  public struct State: Equatable {
    let rank: String?
    let imageUrl: URL?
    let abbreviation: String
    let fullname: String
    let priceInfo: PriceInfo?
    struct PriceInfo: Equatable {
      var change24hText: String {
        String(format: "%.1f", abs(change24h)) + "%"
      }
      let current: Double
      let change24h: Double
    }
  }
  
  enum ViewType {
    case primary
    case secondary(hasRank: Bool)
  }
}

private extension SearchListRow.State {
  var coinState: CoinView.State {
    .init(
      imageUrl: imageUrl,
      abbreviation: abbreviation,
      fullname: fullname
    )
  }
}

private extension NSDirectionalEdgeInsets {
  static let searchListRow = Self(top: 8, leading: 16, bottom: 8, trailing: 16)
}

private extension SearchListRow.State {
  static let expandRow = Self(
    rank: nil,
    imageUrl: nil,
    abbreviation: "추가 코인 로드",
    fullname: "추가 코인 로드",
    priceInfo: nil
  )
}
