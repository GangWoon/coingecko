import protocol Foundation.LocalizedError
import SQLite

#if DEBUG
extension RecentSearchesClient {
  /// 빌드를 위한 객체입니다. 데이터 레이스로부터 안전하지 않기 때문에 preview이외의 용도론 사용하지 마세요.
  final class Box: @unchecked Sendable {
    var recentSearches: [RecentSearch]
    init(recentSearches: [RecentSearch]) { self.recentSearches = recentSearches }
  }
  public static func preview(_ recentSearches: [RecentSearch]) -> Self {
    let copy = Box(recentSearches: recentSearches)
    
    return .init(
      load: { copy.recentSearches },
      save: {
        copy.recentSearches.append($0)
      }
    )
  }
  
  public static let error = Self(
    load: { throw _Error.synthetic },
    save: { _ in throw _Error.synthetic }
  )
  
  enum _Error: Error, LocalizedError, Sendable {
    var errorDescription: String? {
      """
      서버로 부터 데이터를 받아올 수 있는 양을 초과했습니다.
      live value가 아닌, test value로 변경시켜주세요.
      """
    }
    case synthetic
  }
}
#endif
