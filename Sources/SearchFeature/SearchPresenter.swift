import Foundation

// MARK: - Read in Interactor
/// View Model Middleware
@MainActor
public protocol SearchPresentationLogic: AnyObject {
  func updateList(_ response: SearchFeature.UpdateList.Response)
  func updateSection(_ response: SearchFeature.UpdateList.ResponseType)
  func changeDestination(_ destination: SearchFeature.Destination)
}

// MARK: - Read in View
@MainActor
public protocol SearchDisplayLogic: AnyObject {
  func applySnapshot(_ viewModel: SearchFeature.UpdateList.ViewModel)
  func reloadSection(
    _ viewModel: [SearchFeature.RowData],
    section: SearchFeature.SectionType
  )
  func presentAlert(message: String)
}

public final class SearchPresenter {
  public weak var viewController: SearchDisplayLogic?
  
  public init(viewController: SearchDisplayLogic? = nil) {
    self.viewController = viewController
  }
}

extension SearchPresenter: SearchPresentationLogic {
  public func updateSection(_ response: SearchFeature.UpdateList.ResponseType) {
    viewController?.reloadSection(response.rowData, section: response.viewType)
  }
  
  public func updateList(_ response: SearchFeature.UpdateList.Response) {
    var dataSource: [SearchFeature.SectionType: [SearchFeature.RowData]] = [:]
    switch response {
    case .information(let source):
      dataSource[.history] = source.recentSearchs.map(\.rowDatum)
      dataSource[.trending] = source.trending.rowData
      dataSource[.highlight] = source.highlight.rowData
      viewController?.applySnapshot(.information(dataSource))
    case .loading:
      viewController?.applySnapshot(.loading)
    case .search(let source):
      viewController?.applySnapshot(.search(source.rowData))
    }
  }
  
  public func changeDestination(_ destination: SearchFeature.Destination) {
    switch destination {
    case .alert(let message):
      viewController?.presentAlert(message: message)
    }
  }
}

private extension SearchFeature.Coin {
  var rowDatum: SearchFeature.RowData {
    .init(
      rank: marketCapRank,
      imageUrl: thumb,
      name: symbol,
      fullname: name,
      price: price
    )
  }
  
  var price: SearchFeature.RowData.Price? {
    if let currentPrice {
      return .init(current: currentPrice, change24h: priceChangePercentage24H ?? 0)
    }
    return nil
  }
}

private extension SearchFeature.NFT {
  var rowDatum: SearchFeature.RowData {
    .init(
      imageUrl: thumb,
      name: symbol,
      fullname: name,
      price: .init(
        current: floorPriceInNativeCurrency,
        change24h: floorPrice24HPercentageChange
      )
    )
  }
}

private extension SearchFeature.Category {
  var rowDatum: SearchFeature.RowData {
    .init(
      name: "",
      fullname: name,
      price: .init(current: 0, change24h: marketCap1HChange)
    )
  }
}

private extension SearchFeature.UpdateList.ResponseType {
  var rowData: [SearchFeature.RowData] {
    switch self {
    case .trending(let trending):
      return trending.rowData
    case .highlight(let highlight):
      return highlight.rowData
    }
  }
  
  var viewType: SearchFeature.SectionType {
    switch self {
    case .trending:
      return .trending
    case .highlight:
      return .highlight
    }
  }
}

private extension SearchFeature.UpdateList.Response.Information.Trending {
  var rowData: [SearchFeature.RowData] {
    switch selectedCategory {
    case .coin:
      let rowData = data.coins.map(\.rowDatum)
      return isExpanded 
      ? rowData
      : Array(rowData.prefix(7)) + [.expanedRow]
    case .nft:
      return data.nfts.map(\.rowDatum)
    case .category:
      return data.categories.map(\.rowDatum)
    }
  }
}

private extension SearchFeature.UpdateList.Response.Information.Highlight {
  var rowData: [SearchFeature.RowData] {
    switch selectedCategory {
    case .topGainers:
      return data.topGainer
        .prefix(7)
        .map(\.rowDatum)
    case .topLosers:
      return data.topLoser
        .prefix(7)
        .map(\.rowDatum)
    case .newListings:
      return data.newCoins
        .prefix(7)
        .map(\.rowDatum)
    }
  }
}

public extension SearchFeature.RowData {
  static let expanedRow = Self(name: "추가 코인 로드", fullname: "추가 코인 로드")
}

private extension SearchFeature.SearchApi.Response {
  var rowData: [SearchFeature.SectionType: [SearchFeature.RowData]] {
    var rowData: [SearchFeature.SectionType: [SearchFeature.RowData]] = [:]
    rowData[.coin] = Array(coins.prefix(5).map(\.rowDatum))
    /// access denied beacuse of server
    rowData[.nft] = Array(nfts.prefix(5).map(\.rowDatum))
    rowData[.exchange] = Array(exchanges.prefix(5).map(\.rowDatum))
      
    return rowData
  }
}
private extension SearchFeature.SearchApi.Response.Item {
  var rowDatum: SearchFeature.RowData {
    .init(
      rank: rank,
      imageUrl: thumb.hasPrefix("https://") ? thumb : nil,
      name: name ?? "",
      fullname: symbol,
      price: nil
    )
  }
}
