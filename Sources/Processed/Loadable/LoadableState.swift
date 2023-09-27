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

/// An enumeration representing the possible states of a loadable resource.
public enum LoadableState<Value> {

  /// Represents the state where the resource has not yet been requested or is missing.
  case absent

  /// Represents the state where the resource is currently being loaded.
  case loading

  /// Represents the state where an error occurred during the loading process.
  ///
  /// - Parameter Error: The error that occurred while attempting to load the resource.
  case error(Error)

  /// Represents the state where the resource has been successfully loaded.
  ///
  /// - Parameter Value: The successfully loaded resource.
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

/// An extension providing utility methods for manipulating and querying the state of `LoadableState`.
extension LoadableState {

  /// Sets the state to `absent`.
  public mutating func setAbsent() {
    self = .absent
  }

  /// Sets the state to `loading`.
  public mutating func setLoading() {
    self = .loading
  }

  /// Sets the state to `error` with the given error payload.
  ///
  /// - Parameter error: The error that occurred while attempting to load the resource.
  public mutating func setError(_ error: Swift.Error) {
    self = .error(error)
  }

  /// Sets the state to a mock`error` object.
  ///
  /// You can use this for testing or previewing purposes.
  public mutating func setMockError() {
    self = .error(NSError(domain: "mockerror", code: 0))
  }

  /// Sets the state to `loaded` with the given value payload.
  ///
  /// - Parameter value: The successfully loaded resource.
  public mutating func setValue(_ value: Value) {
    self = .loaded(value)
  }

  // MARK: - Convenience Methods

  /// A Boolean value indicating whether the state is `absent`.
  public var isAbsent: Bool {
    if case .absent = self { return true }
    return false
  }

  /// A Boolean value indicating whether the state is `loading`.
  public var isLoading: Bool {
    if case .loading = self { return true }
    return false
  }

  /// A Boolean value indicating whether the state is `error`.
  public var isError: Bool {
    if case .error = self { return true }
    return false
  }

  /// A Boolean value indicating whether the state is `loaded`.
  public var isLoaded: Bool {
    if case .loaded = self { return true }
    return false
  }

  /// The error payload if the state is `error`, otherwise `nil`.
  public var error: Swift.Error? {
    if case .error(let error) = self { return error }
    return nil
  }

  /// The value payload if the state is `loaded`, otherwise `nil`.
  public var data: Value? {
    if case .loaded(let data) = self { return data }
    return nil
  }
}

extension LoadableState: Sendable where Value: Sendable {}
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
