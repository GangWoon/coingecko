import struct Foundation.Data

public struct UndocumentedPayload: Sendable, Hashable {
  public var headerFields: [HTTPField]
  public var body: Data?
  
  public init(
    headerFields: [HTTPField] = [],
    body: Data? = nil
  ) {
    self.headerFields = headerFields
    self.body = body
  }
}
