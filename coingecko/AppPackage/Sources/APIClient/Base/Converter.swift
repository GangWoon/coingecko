import Foundation

struct Converter {
  let decoder: JSONDecoder
  
  init(decoder: JSONDecoder = .init()) {
    self.decoder = decoder
    decoder.keyDecodingStrategy = .convertFromSnakeCase
  }
  
  func getResponseBodyAsJson<T: Decodable, C>(
    _ type: T.Type,
    from data: Data,
    transforming transform: (T) -> C
  ) throws -> C {
    let paresedValue = try decoder.decode(type, from: data)
    return transform(paresedValue)
  }
}
