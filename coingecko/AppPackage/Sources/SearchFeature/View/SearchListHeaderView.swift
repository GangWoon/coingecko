import CombineExt
import ViewHelper
import Combine
import UIKit

final class SearchListHeaderView: UITableViewHeaderFooterView {
  private var selected: CurrentValueSubject<ButtonState?, Never> = .init(nil)
  private var cancellables: Set<AnyCancellable> = []
  
  @discardableResult
  func build(
    title: String,
    buttonStates: [ButtonState] = [],
    selectedItem: Int? = nil
  ) -> AnyPublisher<Int, Never> {
    let stack = UIStackView(alignment: .leading)
    let titleLabel = UILabel(
      text: title,
      font: .systemFont(ofSize: 18, weight: .medium)
    ).addPadding()
    stack.addArrangedSubview(titleLabel)
    
    let buttonList = buttonStates
      .enumerated()
      .map { (index, state) in
        let button = buildButton(
          index: index,
          state: state,
          isSelected: index == selectedItem
        )
        
        return button
      }
    
    let wrappedView = buttonList
      .map { $0.addPadding(leading: 4, bottom: 4, trailing: 4) }
    let hstack = UIStackView(.horizontal, alignment: .leading, subviews: wrappedView)
    hstack.addSpacing()
    stack.addArrangedSubview(hstack)
    contentView.addSubview(stack)
    stack.equalToParent()
    
    return bindingViewState(
      buttonStates: buttonStates,
      buttonList: buttonList,
      selectedItem: selectedItem
    )
  }
  
  private func buildButton(
    index: Int,
    state: ButtonState,
    isSelected: Bool
  ) -> UIButton {
    let button = UIButton(
      configuration: .bordered(),
      primaryAction: .init { [weak self] _ in
        self?.selected.send(state)
        state.action()
      }
    )
    buildButtonConfiguration(
      button: button,
      title: state.title
    )
    if isSelected {
      button.isSelected = true
    }
    
    return button
  }
  
  private func buildButtonConfiguration(button: UIButton, title: String) {
    button.configuration?.cornerStyle = .capsule
    button.configuration?.background.backgroundColor = .green
    button.configuration?.baseBackgroundColor = .clear
    button.changesSelectionAsPrimaryAction = true
    button.configurationUpdateHandler = { button in
      button.configuration?.baseForegroundColor = button.isSelected ? .systemGreen : .black
      button.configuration?.background.backgroundColor = button.isSelected ? .green.withAlphaComponent(0.1) : .clear
    }
    var title = AttributedString(title)
    title.font = .systemFont(ofSize: 14)
    button.configuration?.attributedTitle = title
  }
  
  private func bindingViewState(
    buttonStates: [ButtonState],
    buttonList: [UIButton],
    selectedItem: Int?
  ) -> AnyPublisher<Int, Never> {
    let subject = PassthroughSubject<Int, Never>()
    selected
      .pairwise()
      .sink { [weak subject] old, new in
        if let old , let index = buttonStates.firstIndex(of: old) {
          buttonList[index].isSelected = false
        }
        if let new, let index = buttonStates.firstIndex(of: new) {
          if new == old {
            buttonList[index].isSelected.toggle()
            return
          }
          subject?.send(index)
        }
      }
      .store(in: &cancellables)
    if
      let selectedItem,
      buttonStates.indices.contains(selectedItem)
    {
      selected.send(buttonStates[selectedItem])
    }
    
    return subject.eraseToAnyPublisher()
  }
}

extension SearchListHeaderView {
  struct ButtonState: Equatable {
    let title: String
    let action: () -> Void
    
    static func == (
      lhs: SearchListHeaderView.ButtonState,
      rhs: SearchListHeaderView.ButtonState
    ) -> Bool {
      lhs.title == rhs.title
    }
  }
}
