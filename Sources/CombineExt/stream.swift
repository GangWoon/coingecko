#if canImport(Combine)
import class Combine.AnyCancellable
import class Foundation.NSLock

extension AnyCancellable {
  public var stream: Void {
    get async throws {
      let box = Box()
      let stream: AsyncStream<Void> = .init { continuation in
        box.set(self)
        continuation.onTermination = { _ in
          box.cancel()
        }
      }
      
      for await _ in stream {
        try await Task.sleep(nanoseconds: 1_000_000_000)
      }
    }
  }
}

private final class Box {
  private var lock: NSLock = .init()
  private weak var subscription: AnyCancellable?
  
  func set(_ subscription: AnyCancellable) {
    lock.lock()
    defer { lock.unlock() }
    self.subscription = subscription
  }
  
  func cancel() {
    lock.lock()
    defer { lock.unlock() }
    subscription?.cancel()
    subscription = nil
  }
}
#endif
