import HTTPTypes
import Foundation

public enum Operations {
  public enum Trending {
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
  
  public enum Highlight {
    public struct Input: Sendable {
      struct Query: Sendable, Hashable {
        
      }
    }
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


