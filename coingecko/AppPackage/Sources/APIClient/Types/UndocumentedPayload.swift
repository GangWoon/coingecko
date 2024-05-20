import struct HTTPTypes.HTTPFields
import struct Foundation.Data

public struct UndocumentedPayload: Sendable, Hashable {
  public var headerFields: HTTPFields
  public var body: Data?
  
  public init(
    headerFields: HTTPFields = [:],
    body: Data? = nil
  ) {
    self.headerFields = headerFields
    self.body = body
  }
}
