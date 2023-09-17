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

@MainActor
public protocol LoadableSupport: AnyObject {
  
  func cancel<Value>(_ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>)
  func reset<Value>(_ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>)

  func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self,LoadableState<Value>>,
    silently runSilently: Bool,
    priority: TaskPriority?,
    block: @escaping () async throws -> Value
  )

  func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self,LoadableState<Value>>,
    silently runSilently: Bool,
    priority: TaskPriority?,
    block: @escaping () async throws -> Value
  ) async

  func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self,LoadableState<Value>>,
    silently runSilently: Bool,
    priority: TaskPriority?,
    block: @escaping (_ yield: (_ state: LoadableState<Value>) -> Void) async throws -> Void
  )

  func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self,LoadableState<Value>>,
    silently runSilently: Bool,
    priority: TaskPriority?,
    block: @escaping (_ yield: (_ state: LoadableState<Value>) -> Void) async throws -> Void
  ) async
}

extension LoadableSupport {
  
  public func cancel<Value>(_ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>) {
    let identifier = ProcessIdentifier(
      identifier: ObjectIdentifier(self),
      keyPath: loadableState
    )
    tasks[identifier]?.cancel()
    tasks.removeValue(forKey: identifier)
  }

  public func reset<Value>(_ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>) {
    if case .absent = self[keyPath: loadableState] {} else {
      self[keyPath: loadableState] = .absent
    }
    cancel(loadableState)
  }

  public func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool = false,
    priority: TaskPriority? = nil,
    block: @escaping () async throws -> Value
  ) {
    let identifier = ProcessIdentifier(
      identifier: ObjectIdentifier(self),
      keyPath: loadableState
    )
    tasks[identifier]?.cancel()
    tasks[identifier] = Task(priority: priority) {
      defer { // Cleanup
        tasks[identifier] = nil
      }
      await load(
        loadableState,
        silently: runSilently,
        priority: priority,
        block: block
      )
    }
  }

  public func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool = false,
    priority: TaskPriority? = nil,
    block: @escaping () async throws -> Value
  ) async {
    do {
      if !runSilently { self[keyPath: loadableState] = .loading }
      self[keyPath: loadableState] = try await .loaded(block())
    } catch is CancellationError {
      // Task was cancelled. Don't change the state anymore
    } catch is CancelLoadable {
      self[keyPath: loadableState] = .absent
    } catch {
      self[keyPath: loadableState] = .error(error)
    }
  }

  public func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool = false,
    priority: TaskPriority? = nil,
    block: @escaping (_ yield: (_ state: LoadableState<Value>) -> Void) async throws -> Void
  ) {
    let identifier = ProcessIdentifier(
      identifier: ObjectIdentifier(self),
      keyPath: loadableState
    )
    tasks[identifier]?.cancel()
    tasks[identifier] = Task(priority: priority) {
      defer { // Cleanup
        tasks[identifier] = nil
      }
      await load(
        loadableState,
        silently: runSilently,
        priority: priority,
        block: block
      )
    }
  }

  public func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool = false,
    priority: TaskPriority? = nil,
    block: @escaping (_ yield: (_ state: LoadableState<Value>) -> Void) async throws -> Void
  ) async {
    do {
      if !runSilently { self[keyPath: loadableState] = .loading }
      try await block { state in
        self[keyPath: loadableState] = state
      }
    } catch is CancellationError {
      // Task was cancelled. Don't change the state anymore
    } catch is CancelLoadable {
      self[keyPath: loadableState] = .absent
    } catch {
      self[keyPath: loadableState] = .error(error)
    }
  }
}
