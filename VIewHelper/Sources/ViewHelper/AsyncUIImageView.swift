import class Foundation.URLSession
import class Foundation.NSString
import class Foundation.NSCache
import class Foundation.NSCoder
import class UIKit.UIImageView
import class UIKit.UIImage

import struct Foundation.Data
import struct Foundation.URL

public class AsyncUIImageView: UIImageView {
  public var url: URL?
  private var placeholder: UIImage?
  private let cache: ImageCache
  private var task: Task<Void, Never>?
  
  public init(
    url: URL? = nil,
    placeholder: UIImage? = nil,
    cache: ImageCache = .shared
  ) {
    self.url = url
    self.placeholder = placeholder
    self.cache = cache
    super.init(frame: .zero)
    build()
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    cancel()
  }
  
  private func cancel() {
    task?.cancel()
    task = nil
  }
  
  private func build() {
    task = Task {
      defer { task = nil }
      do {
        guard let url else { throw InternalError.undefined }
        let data = try await cache.fetch(url)
        image = UIImage(data: data)
      } catch {
        image = placeholder != nil
        ? placeholder
        : UIImage(systemName: "exclamationmark.square")
      }
    }
  }
}

extension AsyncUIImageView {
  enum InternalError: Error {
    case undefined
  }
}

public actor ImageCache {
  public static let shared = ImageCache()
  private var cache: NSCache<NSString, Entry.Object> = .init()
  enum Entry {
    final class Object {
      let entry: Entry
      init(entry: Entry) {
        self.entry = entry
      }
    }
    case inProgress(Task<Data, Error>)
    case ready(Data)
  }
  
  private init() { }
  
  func fetch(_ url: URL) async throws -> Data {
    let key = url.absoluteString as NSString
    if let value = cache.object(forKey: key) {
      switch value.entry {
      case let .inProgress(task):
        return try await task.value
      case let .ready(data):
        return data
      }
    } else {
      let task = Task {
        do {
          return try await URLSession.shared.data(from:url).0
        } catch {
          cache.removeObject(forKey: key)
          throw error
        }
      }
      cache.setObject(.init(entry: .inProgress(task)), forKey: key)
      return try await withTaskCancellationHandler {
        let result  = try await task.value
        cache.setObject(.init(entry: .ready(result)), forKey: key)
        return result
      } onCancel: {
        task.cancel()
      }
    }
  }
}
