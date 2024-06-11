@MainActor
public protocol ViewStateRemover: AnyObject {
  var viewStateRemover: [() -> ()?] { get set }
  func removeState()
}

public extension ViewStateRemover {
  func removeState() {
    viewStateRemover
      .forEach { $0() }
    viewStateRemover = []
  }
}
