import ViewHelper
import Combine
import UIKit

public final class SearchViewController: UIViewController {
  private var datasource: UITableViewDiffableDataSource<SectionType, CoinData>!
  private var cancellables: Set<AnyCancellable> = []
  
  public init() {
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
      }
    }
    textField.addAction(action, for: .valueChanged)
    
    return textField.bottomAnchor
  }
  
  private func buildList(bottmAnchor: NSLayoutYAxisAnchor) {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    tableView.register(type: SearchListRow.self)
    tableView.registerForHeaderFooterView(type: SearchListHeaderView.self)
    tableView.delegate = self
    view.addSubview(tableView)
    datasource = .init(tableView: tableView, cellProvider: { tableView, indexPath, datum in
      guard
        let cell = tableView.dequeueReusableCell(type: SearchListRow.self, for: indexPath)
      else { return .init() }
      let section = SectionType(rawValue: indexPath.section) ?? .highlight
      cell.build(type: section, state: datum.rowState)

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
    Task {
      if #available(iOS 16.0, *) {
        try await Task.sleep(for: .seconds(0.2))
        var snapShot = NSDiffableDataSourceSnapshot<SectionType, CoinData>()
        snapShot.appendSections(SectionType.allCases)
        snapShot.appendItems([.init(rank: 4, imageUrl: "asdfzcxv", name: "asdf", fullname: "zxcv", currentPrice: 42342, priceChange24h: 2.1), .init(rank:6, imageUrl: "asdfzcxv", name: "asdf", fullname: "zxcv", currentPrice: 324, priceChange24h: 4.3), ], toSection: .history)
        snapShot.appendItems(
          [.init(rank: 3, imageUrl: "asdfzcxv3", name: "asdf3", fullname: "zxcv3", currentPrice: 133, priceChange24h: 4.6),
           .init(rank: 523, imageUrl: "asdfzcxv3", name: "asdf3", fullname: "zxcv3", currentPrice: 14235, priceChange24h: 43.2),
          ], toSection: .popularity)
        snapShot.appendItems([.init(rank: 2, imageUrl: "asdfzcxv", name: "asdf2", fullname: "zxcv2", currentPrice: 3501, priceChange24h: 2.8)], toSection: .highlight)
        await datasource.apply(snapShot)
      } else {
        // Fallback on earlier versions
      }
    }
  }
}
extension SearchViewController: UITableViewDelegate {
  public func tableView(
    _ tableView: UITableView,
    viewForHeaderInSection section: Int
  ) -> UIView? {
    let section = SectionType(rawValue: section) ?? .history
    switch section {
    case .history:
      let view = tableView.dequeueReusableHeaderFooterView(type: SearchListHeaderView.self)
      view?.build(title: "검색기록")
      return view
    case .popularity:
      let view = tableView.dequeueReusableHeaderFooterView(type: SearchListHeaderView.self)
      
      view?.build(
        title: "인기",
        buttonStates: [
          .init(title: "코인", action: { }),
          .init(title: "NTF", action: { }),
          .init(title: "카테고리", action: { }),
        ],
        selectedItem: 2
      )
      .sink(receiveValue: {
        print("selected \($0)")
      })
      .store(in: &cancellables)
      
      return view
    case .highlight:
      let view = tableView.dequeueReusableHeaderFooterView(type: SearchListHeaderView.self)
      view?.build(
        title: "인기",
        buttonStates: [
          .init(title: "상위 상승 목록", action: { print("상위 상승 목록")}),
          .init(title: "상위 하락 목록", action: { print("상위 하락 목록")}),
          .init(title: "신규 종목", action: { print("신규 종목")}),
        ]
      )
      return view
    }
  }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
  let vc = SearchViewController()
  return vc
}
#endif

struct CoinData: Hashable {
  var rowState: SearchListRow.State {
    .init(
      rank: "\(rank)",
      imageUrl: URL(string: imageUrl),
      abbreviation: name,
      fullname: fullname,
      priceInfo: .init(current: currentPrice, change24h: priceChange24h)
    )
  }
  let rank: Int
  let imageUrl: String
  let name: String
  let fullname: String
  let currentPrice: Double
  let priceChange24h: Double
}
