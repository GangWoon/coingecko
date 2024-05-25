public struct HTTPField: Sendable, Hashable {
  public var name: String
  public var value: String
  
  public init(name: String, value: String) {
    self.name = name
    self.value = value
  }
}
