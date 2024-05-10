import struct HTTPTypes.HTTPRequest

extension HTTPRequest {
  public init(path: String, method: Method) {
    self = .init(method: method, scheme: nil, authority: nil, path: path)
  }
}
