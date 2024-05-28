import Foundation

@MainActor
public protocol SearchPresentationLogic: AnyObject {
  func updateList(_ response: SearchFeature.UpdateList.Response)
  func updateSection(_ response: SearchFeature.UpdateList.ResponseType)
}

@MainActor
public protocol SearchDisplayLogic: AnyObject {
  func applySnapshot(_ viewModel: SearchFeature.UpdateList.ViewModel)
  func reloadSection(
    _ viewModel: [SearchFeature.RowData],
    section: SearchFeature.SectionType
  )
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
    dataSource[.trending] = response.trending.rowData
    dataSource[.highlight] = response.highlight.rowData
    viewController?.applySnapshot(.init(dataSource: dataSource))
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

private extension SearchFeature.UpdateList.Response.Trending {
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

private extension SearchFeature.UpdateList.Response.Highlight {
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
