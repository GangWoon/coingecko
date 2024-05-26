import class UIKit.UIViewController

open class BaseViewController: UIViewController {
  public var _task: Task<Void, Never>?
  
  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    _task = Task { await task() }
  }
  
  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    _task?.cancel()
  }
  
  open func task() async { }
}
