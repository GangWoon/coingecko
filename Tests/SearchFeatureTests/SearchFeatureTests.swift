@testable import SearchFeature
import XCTest

@MainActor
final class SearchFeatureTests: XCTestCase {
  static var mockWorker: MockWorker = .init()
  static var mockPresenter: MockPresenter = .init()
  
  override class func tearDown() {
    super.tearDown()
    mockWorker = .init()
    mockPresenter = .init()
  }
  
  func testPrepareHappyFlow() async throws {
    let expectation1 = XCTestExpectation(description: "Load Search History")
    let expectation2 = XCTestExpectation(description: "Get Trending")
    let expectation3 = XCTestExpectation(description: "Get Highlight")
    let expectation4 = XCTestExpectation(description: "Update List")
    SearchFeatureTests.mockWorker._loadSearchHistory = {
      expectation1.fulfill()
      return .mock
    }
    SearchFeatureTests.mockWorker._getTrending = {
      expectation2.fulfill()
      return .mock
    }
    SearchFeatureTests.mockWorker._getHighlight = {
      expectation3.fulfill()
      return .mock
    }
    SearchFeatureTests.mockPresenter._updateList = { response in
      let _response = SearchFeature.UpdateList.Response.information(
        .init(
          recentSearchs: .mock,
          trending: .init(
            data: .mock,
            isExpanded: false,
            selectedCategory: .coin
          ),
          highlight: .init(
            data: .mock,
            selectedCategory: .topGainers
          )
        )
      )
      XCTAssertEqual(_response, response)
      expectation4.fulfill()
    }
    
    let interactor = SearchInteractor(worker: SearchFeatureTests.mockWorker)
    interactor.presenter = SearchFeatureTests.mockPresenter
    
    await interactor.prepare()
    
    XCTAssertEqual(.mock, interactor.recentSearches)
    let trending = SearchFeature.FetchTrending.Response.mock
    XCTAssertEqual(trending.coins, interactor.trendingCoins)
    XCTAssertEqual(trending.nfts, interactor.trendingNFTs)
    XCTAssertEqual(trending.categories, interactor.trendingCategories)
    let highlight = SearchFeature.FetchHighlight.Response.mock
    XCTAssertEqual(highlight.topGainer, interactor.topGainer)
    XCTAssertEqual(highlight.topLoser, interactor.topLoser)
    XCTAssertEqual(highlight.newCoins, interactor.newCoins)
    await fulfillment(of: [expectation1, expectation2, expectation3, expectation4])
  }
  
  func testPrepareUnHappyFlow() async {
    let expectation1 = XCTestExpectation(description: "Change Destination")
    SearchFeatureTests.mockWorker._loadSearchHistory = {
      throw _Error.unexpected
    }
    SearchFeatureTests.mockPresenter._changeDestination = { destination in
      if case let .alert(message: message) = destination {
        XCTAssertEqual(_Error.unexpected.errorDescription, message)
        expectation1.fulfill()
      }
    }
    
    let interactor = SearchInteractor(worker: SearchFeatureTests.mockWorker)
    interactor.presenter = SearchFeatureTests.mockPresenter
    await interactor.prepare()
    
    XCTAssertEqual([], interactor.recentSearches)
    XCTAssertEqual([], interactor.trendingCoins)
    XCTAssertEqual([], interactor.trendingNFTs)
    XCTAssertEqual([], interactor.trendingCategories)
    XCTAssertEqual([], interactor.topGainer)
    XCTAssertEqual([], interactor.topLoser)
    XCTAssertEqual([], interactor.newCoins)
    XCTAssertNotNil(interactor.destination)
    await fulfillment(of: [expectation1])
  }
  
  func testSearchFieldChangeHappyFlow() async throws {
    let expectation1 = expectation(description: "Search")
    let expectation2 = expectation(description: "Save Search History")
    let expectation3 = expectation(description: "Update Loading Data")
    let expectation4 = expectation(description: "Update Search Data")
    
    SearchFeatureTests.mockWorker._search = { request in
      expectation1.fulfill()
      XCTAssertEqual(request.query, "ABC")
      return .mock
    }
    SearchFeatureTests.mockWorker._saveSearchHistory = { response in
      XCTAssertEqual(
        response,
        SearchFeature.SearchApi.Response.mock.coins.first!
      )
      expectation2.fulfill()
    }
    SearchFeatureTests.mockPresenter._updateList = { response in
      switch response {
      case .information:
        XCTFail()
      case .loading:
        expectation3.fulfill()
      case .search:
        expectation4.fulfill()
      }
    }
    
    let interactor = SearchInteractor(worker: SearchFeatureTests.mockWorker)
    interactor.presenter = SearchFeatureTests.mockPresenter
    
    interactor.searchFieldChanged("ABC")
    while true {
      if interactor.searchResults != nil {
        break
      }
      await Task.yield()
    }
    XCTAssertEqual(interactor.searchResults, .mock)
    XCTAssertNotNil(interactor.recentSearches)
    await fulfillment(of: [expectation1, expectation2, expectation3, expectation4])
  }
  
  func testSearchFieldChangeDebounceFlow() async throws {
    let expectation1 = expectation(description: "Search")
    let expectation2 = expectation(description: "UpdateList Loading Data")
    var expectation2Flag = false
    let expectation3 = expectation(description: "UpdateList Search Data")
    let expectation4 = expectation(description: "Save Search History")
    SearchFeatureTests.mockWorker._search = { request in
      XCTAssertEqual(request.query, "ABCF")
      expectation1.fulfill()
      return .mock
    }
    SearchFeatureTests.mockWorker._saveSearchHistory = { response in
      XCTAssertEqual(
        response,
        SearchFeature.SearchApi.Response.mock.coins.first!
      )
      expectation4.fulfill()
    }
    SearchFeatureTests.mockPresenter._updateList = { request in
      switch request {
      case .information:
        XCTFail()
      case .loading:
        if !expectation2Flag {
          expectation2.fulfill()
          expectation2Flag.toggle()
        }
      case .search:
        expectation3.fulfill()
      }
    }
    let interactor = SearchInteractor(worker: SearchFeatureTests.mockWorker)
    interactor.presenter = SearchFeatureTests.mockPresenter
    
    interactor.searchFieldChanged("ABC")
    interactor.searchFieldChanged("AC")
    interactor.searchFieldChanged("ABCF")
    
    while true {
      if interactor.searchResults != nil {
        break
      }
      await Task.yield()
    }
    XCTAssertEqual(interactor.searchResults, .mock)
    XCTAssertNotNil(interactor.recentSearches)
    await fulfillment(of: [expectation1, expectation2,  expectation3, expectation4])
  }
  
  func testSearchFieldChangeCancelFlow() async throws {
    let expectation1 = expectation(description: "Update List")
    SearchFeatureTests.mockPresenter._updateList = { response in
      if case .information = response {
        expectation1.fulfill()
      }
    }
    let interactor = SearchInteractor(worker: SearchFeatureTests.mockWorker)
    interactor.presenter = SearchFeatureTests.mockPresenter
    
    interactor.searchFieldChanged("ABC")
    interactor.searchFieldChanged("")
    XCTAssertEqual(interactor.searchResults, nil)
    await fulfillment(of: [expectation1])
  }
  
  func testCategoryTapped() async throws {
    let expectation1 = expectation(description: "Update Section")
    SearchFeatureTests.mockPresenter._updateSection = { _ in
      expectation1.fulfill()
    }
    let interactor = SearchInteractor(
      state: .init(
        trendingCoins: [.mock],
        trendingNFTs: [.mock]
      ),
      worker: SearchFeatureTests.mockWorker
    )
    interactor.presenter = SearchFeatureTests.mockPresenter
    
    interactor.categoryTapped(.init(indexPath: .init(row: 1, section: 0)))
    
    XCTAssertEqual(interactor.selectedTrendingCategory, .nft)
    await fulfillment(of: [expectation1])
  }
  
  func testExpandRowTapped() async throws {
    let expectation1 = expectation(description: "Update Section")
    SearchFeatureTests.mockPresenter._updateSection = { _ in
      expectation1.fulfill()
    }
    let interactor = SearchInteractor(worker: SearchFeatureTests.mockWorker)
    interactor.presenter = SearchFeatureTests.mockPresenter
    
    interactor.tappedExpandRow()
    
    XCTAssertEqual(interactor.isTrendingExpanded, true)
    await fulfillment(of: [expectation1])
  }
}

extension [SearchFeature.SearchApi.Response.Item] {
  static let mock: Self = [
    .init(thumb: "www.bitcoin.com", symbol: "bitcoin")
  ]
}

extension SearchFeature.FetchTrending.Response {
  static let mock: Self =
    .init(
      coins: [.init(id: "ABCD", name: "bitcoin", symbol: "bit")],
      nfts: [.init(id: "ABCD", name: "ABCDE", symbol: "ABCDEF", thumb: "ABCEDFG", floorPriceInNativeCurrency: 2.3, floorPrice24HPercentageChange: 3.4)],
      categories: [.init(id: 43, name: "AEE", marketCap1HChange: 2.4)]
    )
  
}

extension SearchFeature.FetchHighlight.Response {
  static let mock = Self(
    topGainer: [.init(id: "ABC", name: "ABCD", symbol: "ABCDE")],
    topLoser: [.init(id: "EER", name: "DDSZCV", symbol: "AZVWE")],
    newCoins: []
  )
}

extension SearchFeature.SearchApi.Response {
  static let mock = Self(
    coins: .mock,
    nfts: .mock,
    exchanges: .mock
  )
}

extension SearchFeature.Coin {
  static let mock = Self(
    id: "123",
    name: "ABCD",
    symbol: "ABCD"
  )
}

extension SearchFeature.NFT {
  static let mock = Self(
    id: "123",
    name: "ABCD",
    symbol: "ABCD",
    thumb: "ABCD",
    floorPriceInNativeCurrency: 3.4,
    floorPrice24HPercentageChange: 2.4
  )
}

extension SearchFeature.Category {
  static let mock = Self(
    id: 12,
    name: "ABCD",
    marketCap1HChange: 3.4
  )
}

struct MockPresenter: SearchPresentationLogic {
  var _updateList: ((SearchFeature.UpdateList.Response) -> Void)?
  var _updateSection: ((SearchFeature.UpdateList.ResponseType) -> Void)?
  var _changeDestination: ((SearchFeature.Destination)-> Void)?
  
  func updateList(_ response: SearchFeature.UpdateList.Response) {
    if let _updateList {
      _updateList(response)
    } else {
      XCTFail()
    }
  }
  
  func updateSection(_ response: SearchFeature.UpdateList.ResponseType) {
    if let _updateSection {
      _updateSection(response)
    } else {
      XCTFail()
    }
  }
  
  func changeDestination(_ destination: SearchFeature.Destination) {
    if let _changeDestination {
      _changeDestination(destination)
    } else {
      XCTFail()
    }
  }
}

struct MockWorker: SearchWorkerInterface {
  var _loadSearchHistory: (() throws -> [SearchFeature.SearchApi.Response.Item])?
  var _saveSearchHistory: ((SearchFeature.SearchApi.Response.Item) throws -> Void)?
  var _getTrending: (() async throws -> SearchFeature.FetchTrending.Response)?
  var _getHighlight: (() async throws -> SearchFeature.FetchHighlight.Response)?
  var _search: ((SearchFeature.SearchApi.Request) async throws -> SearchFeature.SearchApi.Response)?
  
  func loadSearchHistory() throws -> [SearchFeature.SearchApi.Response.Item] {
    if let _loadSearchHistory {
      return try _loadSearchHistory()
    } else {
      fatalError()
    }
  }
  
  func saveSearchHistory(_ item: SearchFeature.SearchApi.Response.Item) throws {
    if let _saveSearchHistory {
      try _saveSearchHistory(item)
    } else {
      fatalError()
    }
  }
  
  func getTrending() async throws -> SearchFeature.FetchTrending.Response {
    if let _getTrending {
      return try await _getTrending()
    } else {
      fatalError()
    }
  }
  
  func getHighlight() async throws -> SearchFeature.FetchHighlight.Response {
    if let _getHighlight {
      return try await _getHighlight()
    } else {
      fatalError()
    }
  }
  
  func search(request: SearchFeature.SearchApi.Request) async throws -> SearchFeature.SearchApi.Response {
    if let _search {
      return try await _search(request)
    } else {
      fatalError()
    }
  }
}

enum _Error: Error, LocalizedError {
  var errorDescription: String? {
    "Unexpected Error"
  }
  case unexpected
}
