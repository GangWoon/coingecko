import struct Foundation.Data

public struct HTTPRequest: Sendable, Hashable {
  public var path: String?
  
  public var queries: [Query]
  public struct Query: Sendable, Hashable {
    public var name: String
    public var value: String
    public init(name: String, value: String) {
      self.name = name
      self.value = value
    }
  }
  
  public var method: Method
  public enum Method: String, Sendable, Hashable {
    case get = "GET"
    case put = "PUT"
  }
  
  public var headerFields: [HTTPField]
  public var body: Data?
  
  public init(
    path: String? = nil,
    queries: [Query] = [],
    method: Method = .get,
    headerFields: [HTTPField] = [],
    body: Data? = nil
  ) {
    self.path = path
    self.queries = queries
    self.method = method
    self.headerFields = headerFields
    self.body = body
  }
}
