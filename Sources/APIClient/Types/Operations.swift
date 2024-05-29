import struct HTTPClient.UndocumentedPayload
import Foundation

public enum Operations {
  public enum Trending {
    public struct Input: Sendable {
      public init() { }
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
        
        public init(body: Body) {
          self.body = body
        }
      }
      
      case ok(Ok)
      case undocumented(statusCode: Int, UndocumentedPayload)
    }
  }
  
  public enum Coin {
    public struct Input: Sendable { 
      public init() { }
    }
    public enum Output: Sendable {
      public struct Ok: Sendable {
        public enum Body: Sendable {
          public var json: [Components.Schemas.Coin] {
            get {
              switch self {
              case .json(let value):
                return value
              }
            }
          }
          case json([Components.Schemas.Coin])
        }
        public var body: Body
        
        public init(body: Body) {
          self.body = body
        }
      }
      
      case ok(Ok)
      case undocumented(statusCode: Int, UndocumentedPayload)
    }
  }
}


