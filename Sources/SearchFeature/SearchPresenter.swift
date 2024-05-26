import Foundation

@MainActor
public protocol SearchPresentationLogic: AnyObject {
  func updateList(_ response: SearchFeature.UpdateList.Response)
  func updateSection(_ response: SearchFeature.UpdateList.ResponseType)
}

public final class SearchPresenter {
  public weak var viewController: SearchDisplayLogic?
  
  public init(viewController: SearchDisplayLogic? = nil) {
    self.viewController = viewController
  }
}

extension SearchPresenter: SearchPresentationLogic {
  public func updateSection(_ response: SearchFeature.UpdateList.ResponseType) {
    let section: SearchFeature.SectionType
    let rowData: [SearchFeature.RowData]
    switch response {
    case .trending(let response):
      section = .trending
      switch response.selectedCategory {
      case .coin:
        rowData = response.data.coins.map(\.rowDatum)
      case .nft:
        rowData = response.data.nfts.map(\.rowDatum)
      case .category:
        rowData = response.data.categories.map(\.rowDatum)
      }
    case .highlight(let response):
      section = .highlight
      switch response.selectedCategory {
      case .topGainers:
        rowData = response.data.topGainer.map(\.rowDatum)
      case .topLosers:
        rowData = response.data.topLoser.map(\.rowDatum)
      case .newListings:
        rowData = response.data.newCoins.prefix(7).map(\.rowDatum)
      }
    }
    
    viewController?.reloadSection(rowData, section: section)
  }
  
  public func updateList(_ response: SearchFeature.UpdateList.Response) {
    var dataSource: [SearchFeature.SectionType: [SearchFeature.RowData]] = [:]
    switch response.selectedTrendingCategory {
    case .coin:
      dataSource[.trending] = response.trendingResponse.coins.map(\.rowDatum)
    case .nft:
      dataSource[.trending] = response.trendingResponse.nfts.map(\.rowDatum)
    case .category:
      dataSource[.trending] = response.trendingResponse.categories.map(\.rowDatum)
    }
    
    switch response.selectedHighlightCategory {
    case .topGainers:
      dataSource[.highlight] = response.highlightResponse.topGainer
        .prefix(7)
        .map(\.rowDatum)
    case .topLosers:
      dataSource[.highlight] = response.highlightResponse.topLoser
        .prefix(7)
        .map(\.rowDatum)
    case .newListings:
      dataSource[.highlight] = response.highlightResponse.newCoins
        .prefix(7)
        .map(\.rowDatum)
    }
    
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
