//
//  Copyright © 2023 Dennis Müller and all collaborators
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public enum LoadableState<Value> {
  case absent
  case loading
  case error(Error)
  case loaded(Value)
}

extension LoadableState: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .absent:
      return "absent"
    case .loading:
      return "loading"
    case .error(let error):
      return "error(\(error.localizedDescription))"
    case .loaded(let value):
      return "loaded(\(value))"
    }
  }
}

extension LoadableState {
  
  public mutating func setAbsent() {
    self = .absent
  }
  
  public mutating func setLoading() {
    self = .loading
  }
  
  public mutating func setError(_ error: Swift.Error) {
    self = .error(error)
  }
  
  public mutating func setValue(_ value: Value) {
    self = .loaded(value)
  }
  
  // MARK: - Convenience Methods
  
  public var isAbsent: Bool {
    if case .absent = self { return true }
    return false
  }
  
  public var isLoading: Bool {
    if case .loading = self { return true }
    return false
  }
  
  public var isError: Bool {
    if case .error = self { return true }
    return false
  }
  
  public var isLoaded: Bool {
    if case .loaded = self { return true }
    return false
  }
  
  public var error: Swift.Error? {
    if case .error(let error) = self { return error }
    return nil
  }
  
  public var data: Value? {
    if case .loaded(let data) = self { return data }
    return nil
  }
}

extension LoadableState: Equatable where Value: Equatable {
  nonisolated public static func == (
    lhs: LoadableState,
    rhs: LoadableState
  ) -> Bool {
    switch (lhs, rhs) {
    case (.absent, .absent): return true
    case (.loading, .loading): return true
    case (.error, .error): return true
    case (.loaded(let leftData), .loaded(let rightData)): return leftData == rightData
    default: return false
    }
  }
}
