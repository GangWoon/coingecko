#if canImport(Combine)
@preconcurrency import protocol Combine.Publisher

public extension Publisher {
  var stream: AsyncStream<Output> {
    AsyncStream<Output> { continuation in
      let cancellable = self.sink { _ in
        continuation.finish()
      } receiveValue: { value in
        continuation.yield(value)
      }
      
      continuation.onTermination = { _ in
        cancellable.cancel()
      }
    }
  }
}
#endif
