import ViewControllerHelper
import SearchFeature
import ViewHelper
import ApiClient
import UIKit

public final class SearchViewController: BaseViewController {
  public var interactor: any SearchBusinessLogic
  private var datasource: UITableViewDiffableDataSource<SearchFeature.SectionType, SearchFeature.RowData>!
  
  private var indicatorView: UIActivityIndicatorView!
  private var hideKeyboard: (() -> Void)?
  
  public init(interactor: any SearchBusinessLogic) {
    self.interactor = interactor
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    build()
  }
  
  public override func task() async {
    await interactor.prepare()
  }
  
  private func build() {
    let bottomAnchor = buildSearchField()
    buildList(bottmAnchor: bottomAnchor)
  }
  
  private func buildSearchField() -> NSLayoutYAxisAnchor {
    let textField = SearchTextField()
    textField.delegate = self
    textField.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(textField)
    NSLayoutConstraint.activate([
      textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      textField.heightAnchor.constraint(equalToConstant: 60)
    ])
    let action = UIAction { [weak self] action in
      if let textField = action.sender as? UITextField {
        self?.interactor.searchFieldChanged(textField.text)
      }
    }
    textField.addAction(action, for: .editingChanged)
    hideKeyboard = { [weak textField] in
      if let textField, textField.isFirstResponder {
        textField.resignFirstResponder()
      }
    }
    
    return textField.bottomAnchor
  }
  
  private func buildList(bottmAnchor: NSLayoutYAxisAnchor) {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    buildListDataSource(tableView: tableView)
    tableView.register(type: SearchListRow.self)
    tableView.registerForHeaderFooterView(type: SearchListHeaderView.self)
    tableView.delegate = self
    view.addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    buildIndicator(superView: tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: bottmAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
    view.backgroundColor = tableView.backgroundColor
  }
  
  private func buildIndicator(superView: UIView) {
    let indicatorView = UIActivityIndicatorView(style: .large)
    superView.addSubview(indicatorView)
    indicatorView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      indicatorView.centerXAnchor.constraint(equalTo: superView.centerXAnchor),
      indicatorView.centerYAnchor.constraint(equalTo: superView.centerYAnchor, constant: -80)
    ])
    self.indicatorView = indicatorView
  }
  
  private func buildListDataSource(tableView: UITableView) {
    datasource = .init(
      tableView: tableView,
      cellProvider: { [weak self] tableView, indexPath, datum in
        guard let self else { return .init() }
        let cell = tableView.dequeueReusableCell(type: SearchListRow.self, for: indexPath)
        if datum == .expanedRow {
          cell?.buildExpandView(
            datum.rowState,
            action: .init { [weak self] _ in
              self?.interactor.tappedExpandRow()
            }
          )
          return cell
        }
        cell?.build(rowType(indexPath.section), state: datum.rowState)
        
        return cell
      }
    )
  }
}

extension SearchViewController: UITableViewDelegate {
  public func tableView(
    _ tableView: UITableView,
    heightForRowAt indexPath: IndexPath
  ) -> CGFloat { 60 }
  
  public func tableView(
    _ tableView: UITableView,
    viewForHeaderInSection section: Int
  ) -> UIView? {
    let view = tableView.dequeueReusableHeaderFooterView(type: SearchListHeaderView.self)
    let sectionType = datasource
      .snapshot()
      .sectionIdentifiers[section]
    view?.build(
      title: sectionType.title,
      buttonStates: buildButtonStates(sectionType, section: section),
      selectedItem: sectionType.selectedIndex
    )
    
    return view
  }
  
  private func buildButtonStates(
    _ sectionType: SearchFeature.SectionType,
    section: Int
  ) -> [SearchListHeaderView.ButtonState] {
    sectionType.category
      .enumerated()
      .map { row, state in
          .init(
            title: state,
            action: { [weak self] in
              self?.interactor.categoryTapped(.init(indexPath: .init(row: row, section: section)))
            }
          )
      }
  }
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    hideKeyboard?()
  }
}

extension SearchViewController: UITextFieldDelegate {
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
  }
}

extension SearchViewController: SearchDisplayLogic {
  public func applySnapshot(_ viewModel: SearchFeature.UpdateList.ViewModel) {
    var snapShot = NSDiffableDataSourceSnapshot<SearchFeature.SectionType, SearchFeature.RowData>()
    switch viewModel {
    case .information(let dataSoruce),
        .search(let dataSoruce):
      let items = dataSoruce
        .filter { !$0.value.isEmpty }
        .sorted { $0.key.value.0 < $1.key.value.0 }
      snapShot.appendSections(items.map(\.key))
      items.forEach { key, value in
        snapShot.appendItems(value, toSection: key)
      }
      indicatorView.stopAnimating()
    case .loading:
      indicatorView.startAnimating()
    }
    
    datasource.apply(snapShot, animatingDifferences: false)
  }
  
  public func reloadSection(
    _ viewModel: [SearchFeature.RowData],
    section: SearchFeature.SectionType
  ) {
    var snapshot = datasource.snapshot()
    let items = snapshot.itemIdentifiers(inSection: section)
    snapshot.deleteItems(items)
    snapshot.appendItems(viewModel, toSection: section)
    datasource.apply(snapshot, animatingDifferences: false)
  }
  
  public func presentAlert(message: String) {
    let alert = UIAlertController(
      title: "서버 오류",
      message: message,
      preferredStyle: .alert
    )
    alert.addAction(.init(title: "확인", style: .cancel))
    present(alert, animated: true)
  }
}

private extension SearchViewController {
  func rowType(_ section: Int) -> SearchListRow.ViewType {
    let sectionType = datasource.snapshot().sectionIdentifiers
    switch sectionType[section] {
    case .history, .coin, .nft, .exchange:
      return .primary
    case .trending(let index):
      switch index {
      case 0:
        return .secondary(hasRank: true)
      case 1:
        return .secondary(hasRank: false)
      default:
        return .primary
      }
    case .highlight(let index):
      return .secondary(hasRank: index != 2)
    }
  }
}

private extension SearchFeature.SectionType {
  var category: [String] {
    switch self {
    case .trending:
      return SearchFeature.TrendingCategory.allCases
        .map(\.description)
    case .highlight:
      return SearchFeature.HighlightCategory.allCases
        .map(\.description)
    default:
      return []
    }
  }
  
  var selectedIndex: Int {
    switch self {
    case .trending(let index):
      return index
    case .highlight(let index):
      return index
    default:
      return 0
    }
  }
}

private extension SearchFeature.RowData {
  var rowState: SearchListRow.State {
    return .init(
      rank: rank == nil ? nil : String(rank!),
      imageUrl: URL(string: imageUrl ?? ""),
      abbreviation: name,
      fullname: fullname,
      priceInfo: price?.rowState
    )
  }
}

private extension SearchFeature.RowData.Price {
  var rowState: SearchListRow.State.PriceInfo {
    .init(current: current, change24h: change24h)
  }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
  let builder = SearchSceneBuilder(dependency: .live)
  return builder.build()
}
#endif
