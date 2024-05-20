import HTTPTypes
import Foundation

public enum Operations {
  public enum trending {
    public struct Input: Sendable { }
    public enum Output: Sendable {
      public struct Ok: Sendable {
        public enum Body: Sendable {
          public var json: Components.Schemas.Trending {
            get {
              switch self {
              case .json(let trending):
                return trending
              }
            }
          }
          case json(Components.Schemas.Trending)
        }
        public var body: Body
      }
      
      case ok(Ok)
      case undocumented(statusCode: Int, UndocumentedPayload)
    }
  }
}


