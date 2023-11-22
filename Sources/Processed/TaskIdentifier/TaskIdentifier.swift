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

import SwiftUI

/// A property wrapper that provides a unique identifier for SwiftUI tasks.
///
/// `TaskIdentifier` is used to associate a specific ID with a SwiftUI task,
/// allowing the task to be identified or restarted based on changes of that ID.
/// It can be particularly useful for controlling task execution in response to state changes.
///
/// Usage:
///
/// ```swift
/// @TaskIdentifier var identifier
/// var body: some View {
///   Text("My View")
///     .task(id: identifier) { /* Do work */ } // Restarts when the identifier changes
/// }
///
/// func restart() {
///   $identifier.new()
/// }
/// ```
///
/// You can provide a custom type for the id by specifying it:
///
/// ```swift
/// @TaskIdentifier<String> var identifier
/// $identifier.new("New ID")
/// ```
///
/// - Parameter ID: The type of the identifier. This will default to `UUID`.
@propertyWrapper public struct TaskIdentifier<ID>: DynamicProperty where ID: Equatable {
  
  /// The underlying identifier value.
  @State private var id: ID
  
  /// The current value of the identifier.
  public var wrappedValue: ID {
    id
  }
  
  /// Provides access to methods for manipulating the identifier.
  public var projectedValue: Access {
    .init(id: $id)
  }
  
  /// Initializes a new instance with the provided identifier value.
  ///
  /// - Parameter wrappedValue: The initial identifier value.
  public init(wrappedValue: ID) {
    self._id = .init(initialValue: wrappedValue)
  }
  
  /// Initializes a new instance with a UUID identifier.
  public init() where ID == UUID {
    self._id = .init(initialValue: .init())
  }
}

extension TaskIdentifier {
  /// A structure providing methods to manipulate the `TaskIdentifier` value.
  public struct Access {
    
    /// The binding to the underlying identifier.
    @Binding var id: ID
    
    /// Creates a new `Access` instance.
    ///
    /// - Parameter id: A binding to the identifier value.
    fileprivate init(id: Binding<ID>) {
      self._id = id
    }
    
    /// Updates the identifier to a new value.
    ///
    /// - Parameter newId: The new identifier value.
    public func new(_ newId: ID) {
      id = newId
    }
    
    /// Resets the identifier to a new `UUID`.
    public func new() where ID == UUID {
      id = .init()
    }
  }
}
