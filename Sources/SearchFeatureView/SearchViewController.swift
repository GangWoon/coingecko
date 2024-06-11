import ViewControllerHelper
import SearchFeature
import ViewHelper
import ApiClient
import UIKit

public final class SearchViewController: BaseViewController {
  public var interactor: any SearchBusinessLogic
  public var router: any SearchRoutingLogic
  
  private var dataSource: DataSource!
  private typealias DataSource = UITableViewDiffableDataSource<SearchFeature.SectionType, SearchFeature.RowData>
  
  private var searchField: SearchTextField!
  private var tableView: UITableView!
  private var indicatorView: UIActivityIndicatorView!
  
  public init(
    interactor: any SearchBusinessLogic,
    router: any SearchRoutingLogic
  ) {
    self.interactor = interactor
    self.router = router
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
    self.searchField = buildSearchField()
    layoutSearchField()
    tableView = buildList()
    dataSource = buildListDataSource(tableView: tableView)
    layoutList()
    indicatorView = buildIndicator()
    view.backgroundColor = tableView.backgroundColor
  }
  
  private func buildSearchField() -> SearchTextField {
    let textField = SearchTextField()
    textField.delegate = self
    let action = UIAction { [weak self] action in
      if let textField = action.sender as? UITextField {
        self?.interactor.searchFieldChanged(textField.text)
      }
    }
    textField.addAction(action, for: .editingChanged)
    
    return textField
  }
  
  private func layoutSearchField() {
    searchField.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(searchField)
    NSLayoutConstraint.activate([
      searchField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      searchField.heightAnchor.constraint(equalToConstant: 60)
    ])
  }
  
  private func buildList() -> UITableView {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    tableView.register(type: SearchListRow.self)
    tableView.registerForHeaderFooterView(type: SearchListHeaderView.self)
    tableView.delegate = self
    return tableView
  }
  
  private func layoutList() {
    view.addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }
  
  private func buildIndicator() -> UIActivityIndicatorView {
    let indicatorView = UIActivityIndicatorView(style: .large)
    tableView.addSubview(indicatorView)
    indicatorView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      indicatorView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
      indicatorView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -80)
    ])
    
    return indicatorView
  }
  
  private func buildListDataSource(tableView: UITableView) -> DataSource {
    .init(
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
    let sectionType = dataSource
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
    searchField.resignFirstResponder()
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
    case .loading:
      break
    }
    dataSource.apply(snapShot, animatingDifferences: false)
    
    viewModel == .loading
    ? indicatorView.startAnimating()
    : indicatorView.stopAnimating()
  }
  
  public func reloadSection(
    _ viewModel: [SearchFeature.RowData],
    section: SearchFeature.SectionType
  ) {
    var snapshot = dataSource.snapshot()
    guard
      let index = snapshot.sectionIdentifiers.firstIndex(of: section)
    else { return }
    let section = snapshot.sectionIdentifiers[index]
    let items = snapshot.itemIdentifiers(inSection: section)
    
    snapshot.deleteItems(items)
    snapshot.appendItems(viewModel, toSection: section)
    dataSource.apply(snapshot, animatingDifferences: false)
  }
  
  public func presentAlert(message: String) {
    router.presentAlert(message: message)
  }
}

private extension SearchViewController {
  func rowType(_ section: Int) -> SearchListRow.ViewType {
    let sectionType = dataSource.snapshot().sectionIdentifiers
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
  let builder = SearchSceneBuilder(dependency: .preview)
  return builder.build()
}
#endif
