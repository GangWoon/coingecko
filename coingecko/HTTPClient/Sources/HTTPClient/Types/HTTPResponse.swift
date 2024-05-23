import struct Foundation.Data

public struct HTTPResponse: Sendable, Hashable {
  public var statusCode: Int
  public var headerFields: [HTTPField]
  public var body: Data
  
  public init(
    statusCode: Int,
    headerFields: [HTTPField],
    body: Data
  ) {
    self.statusCode = statusCode
    self.headerFields = headerFields
    self.body = body
  }
}
