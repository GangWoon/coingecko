import ViewHelper
import Combine
import UIKit

@MainActor
public protocol SearchDisplayLogic: AnyObject {
  func applySnapshot(_ viewModel: SearchFeature.UpdateList.ViewModel)
  func reloadSection(
    _ viewModel: [SearchFeature.RowData],
    section: SearchFeature.ViewModel.SectionType
  )
}

public final class SearchViewController: BaseViewController {
  private var searchField: SearchTextField!
  var interactor: any SearchDataStore & SearchBusinessLogic
  
  private var datasource: UITableViewDiffableDataSource<SearchFeature.ViewModel.SectionType, SearchFeature.RowData>!
  private var cancellables: Set<AnyCancellable> = []
  
  public init(interactor: any SearchDataStore & SearchBusinessLogic) {
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
    textField.addAction(action, for: .valueChanged)
    searchField = textField
    
    return textField.bottomAnchor
  }
  
  private func buildList(bottmAnchor: NSLayoutYAxisAnchor) {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    tableView.register(type: SearchListRow.self)
    tableView.registerForHeaderFooterView(type: SearchListHeaderView.self)
    tableView.delegate = self
    view.addSubview(tableView)
    datasource = .init(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, datum in
      guard
        let self,
        let cell = tableView.dequeueReusableCell(type: SearchListRow.self, for: indexPath)
      else { return .init() }
      let sectionType = self.interactor.sectionList[indexPath.section]
      switch sectionType {
      case .history:
        cell.build(.primary, state: datum.rowState)
      case .trending:
        cell.build(
          interactor.selectedTrendingCategory.viewType,
          state: datum.rowState
        )
      case .highlight:
        
        cell.build(
          interactor.selectedHighlightCategory.viewType,
          state: datum.rowState
        )
      }
      
      return cell
    })
    tableView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: bottmAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
    
    view.backgroundColor = tableView.backgroundColor
  }
}

extension SearchViewController: UITableViewDelegate {
  public func tableView(
    _ tableView: UITableView,
    heightForRowAt indexPath: IndexPath
  ) -> CGFloat {
    60
  }
  
  public func tableView(
    _ tableView: UITableView,
    viewForHeaderInSection section: Int
  ) -> UIView? {
    let sectionType = interactor.sectionList[section]
    let view = tableView.dequeueReusableHeaderFooterView(type: SearchListHeaderView.self)
    
    var selectedIndex: Int = 0
    switch sectionType {
    case .history:
      break
    case .trending:
      selectedIndex =  interactor.selectedTrendingCategory.rawValue
    case .highlight:
      selectedIndex =  interactor.selectedHighlightCategory.rawValue
    }
    
    view?.build(
      title: sectionType.title,
      buttonStates: buildButtonStates(sectionType, section: section),
      selectedItem: selectedIndex
    )
    return view
  }
  
  private func buildButtonStates(
    _ sectionType: SearchFeature.ViewModel.SectionType,
    section: Int
  ) -> [SearchListHeaderView.ButtonState] {
    let build: ([ListCategoryable]) -> [SearchListHeaderView.ButtonState] = { list in
      list.enumerated()
        .map { row, value in
            .init(
              title: value.description,
              action: { [weak self] in
                self?.interactor.categoryTapped(.init(indexPath: .init(row: row, section: section)))
              }
            )
        }
    }
    switch sectionType {
    case .history:
      return []
    case .trending:
      return build(interactor.trendingCategory)
    case .highlight:
      return build(interactor.highlightCategory)
    }
  }
}

extension SearchFeature.TrendingCategory {
  var viewType: SearchListRow.ViewType {
    switch self {
    case .coin:
      return .secondary(hasRank: true)
    case .nft:
      return .secondary(hasRank: false)
    case .category:
      return .primary
    }
  }
}

extension SearchFeature.HighlightCategory {
  var viewType: SearchListRow.ViewType {
    .secondary(hasRank: self != .newListings)
  }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
  let vc = SearchViewController(
    interactor: SearchInteractor())
  return vc
}
#endif

extension SearchViewController: SearchDisplayLogic {
  public func applySnapshot(_ viewModel: SearchFeature.UpdateList.ViewModel) {
    let items = viewModel.dataSource
      .sorted { $0.key.rawValue < $1.key.rawValue }
    
    var snapShot = NSDiffableDataSourceSnapshot<SearchFeature.ViewModel.SectionType, SearchFeature.RowData>()
    snapShot.appendSections(items.map(\.key))
    items.forEach { key, value in
      snapShot.appendItems(value, toSection: key)
    }
    datasource.apply(snapShot)
  }
  
  public func reloadSection(
    _ viewModel: [SearchFeature.RowData],
    section: SearchFeature.ViewModel.SectionType
  ) {
    var snapshot = datasource.snapshot()
    let items = snapshot.itemIdentifiers(inSection: section)
    snapshot.deleteItems(items)
    
    snapshot.appendItems(viewModel, toSection: section)
    datasource.apply(snapshot)
  }
}


