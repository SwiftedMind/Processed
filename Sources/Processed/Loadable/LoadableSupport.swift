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

/// A protocol that adds support for automatic state and `Task` management for ``Processed/LoadableState`` to the class.
///
/// The provided method takes care of creating a `Task` to load the resource, cancel any previous `Task` instances and setting
/// the appropriate loading states on the ``Processed/LoadableState`` that you specify.
///
/// To start loading a resource, call one of the `load` methods on self with a key path to a ``Processed/LoadableState``
/// property.
///
/// ```swift
///@MainActor final class ViewModel: ObservableObject, LoadableSupport {
///  @Published var numbers: LoadableState<[Int]> = .absent
///
///  func loadNumbers() {
///    load(\.numbers) {
///      return try await fetchNumbers()
///    }
///  }
///}
/// ```
///
/// - Note: This is only meant to be used in classes.
/// If you want to do this inside a SwiftUI view, please refer to the ``Processed/Loadable`` property wrapper.
public protocol LoadableSupport: AnyObject {

  /// Cancels the task of an ongoing resource loading process.
  ///
  /// - Note: You are responsible for cooperating with the task cancellation within the loading closures.
  @MainActor func cancel<Value>(_ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>)

  /// Cancels the task of an ongoing resource loading process and resets the state to `.absent`.
  ///
  /// - Note: You are responsible for cooperating with the task cancellation within the loading closures.
  @MainActor func reset<Value>(_ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>)

  /// Starts a resource loading process in a new `Task`, waiting for a return value or thrown error from the
  /// `block` closure, while setting the ``Processed/LoadableState`` accordingly.
  ///
  /// At the start of this method, any previously created tasks managed by this type will be cancelled
  /// and the loading state will be set to `.loading`, unless `runSilently` is set to true.
  ///
  /// Throwing an error inside the `block` closure will cause a final `.error` state to be set,
  /// while a returned value will cause a final `.loaded` state to be set.
  ///
  /// - Parameters:
  ///   - loadableState: The key path to the ``Processed/LoadableState``.
  ///   - runSilently: If `true`, the state will not be set to `.loading` initially.
  ///   - priority: The priority level for the `Task` that is created and used for the loading process.
  ///   - block: The asynchronous block to run.
  ///
  /// - Returns: The task that runs the asynchronous loading process. You don't have to store it, but you can.
  @MainActor @discardableResult func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool,
    priority: TaskPriority?,
    block: @escaping () async throws -> Value
  ) -> Task<Void, Never>

  /// Starts a resource loading process in the current asynchronous context,
  /// waiting for a return value or thrown error from the `block` closure,
  /// while setting the ``Processed/LoadableState`` accordingly.
  ///
  /// This method does not create its own `Task`, so you must `await` its completion.
  ///
  /// At the start of this method, any previously created tasks managed by this type will be cancelled
  /// and the loading state will be set to `.loading`, unless `runSilently` is set to true.
  ///
  /// Throwing an error inside the `block` closure will cause a final `.error` state to be set,
  /// while a returned value will cause a final `.loaded` state to be set.
  ///
  /// - Parameters:
  ///   - loadableState: The key path to the ``Processed/LoadableState``.
  ///   - runSilently: If `true`, the state will not be set to `.loading` initially.
  ///   - block: The asynchronous block to run.
  @MainActor func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool,
    block: @escaping () async throws -> Value
  ) async

  /// Starts a resource loading process in a new `Task` that continuously yields results
  /// until the `block` closure terminates or fails, while setting the ``Processed/LoadableState`` accordingly.
  ///
  /// At the start of this method, any previously created tasks managed by this type will be cancelled
  /// and the loading state will be set to `.loading`, unless `runSilently` is set to true.
  ///
  /// Throwing an error inside the `block` closure will cause a final `.error` state to be set.
  ///
  /// - Parameters:
  ///   - loadableState: The key path to the ``Processed/LoadableState``.
  ///   - runSilently: If `true`, the state will not be set to `.loading` initially.
  ///   - priority: The priority level for the `Task` that is created and used for the loading process.
  ///   - block: The asynchronous block to run.
  ///   The block exposes a `yield` closure you can call to continuously update the resource loading state over time.
  ///
  /// - Returns: The task that runs the asynchronous loading process. You don't have to store it, but you can.
  @MainActor @discardableResult func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool,
    priority: TaskPriority?,
    block: @escaping (_ yield: (_ state: LoadableState<Value>) -> Void) async throws -> Void
  ) -> Task<Void, Never>

  /// Starts a resource loading process in the current asynchronous context, that continuously yields results
  /// until the `block` closure terminates or fails, while setting the ``Processed/LoadableState`` accordingly.
  ///
  /// This method does not create its own `Task`, so you must `await` its completion.
  ///
  /// At the start of this method, any previously created tasks managed by this type will be cancelled
  /// and the loading state will be set to `.loading`, unless `runSilently` is set to true.
  ///
  /// Throwing an error inside the `block` closure will cause a final `.error` state to be set.
  ///
  /// - Parameters:
  ///   - loadableState: The key path to the ``Processed/LoadableState``.
  ///   - runSilently: If `true`, the state will not be set to `.loading` initially.
  ///   - block: The asynchronous block to run.
  ///   The block exposes a `yield` closure you can call to continuously update the resource loading state over time.
  @MainActor func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool,
    block: @escaping (_ yield: (_ state: LoadableState<Value>) -> Void) async throws -> Void
  ) async
}

extension LoadableSupport {

  @MainActor public func cancel<Value>(_ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>) {
    let identifier = TaskStore.shared.identifier(for: loadableState, in: self)
    TaskStore.shared.tasks[identifier]?.cancel()
    TaskStore.shared.tasks.removeValue(forKey: identifier)
  }

  @MainActor public func reset<Value>(_ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>) {
    if case .absent = self[keyPath: loadableState] {} else {
      self[keyPath: loadableState] = .absent
    }
    cancel(loadableState)
  }

  @MainActor @discardableResult public func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool = false,
    priority: TaskPriority? = nil,
    block: @escaping () async throws -> Value
  ) -> Task<Void, Never> {
    let identifier = TaskStore.shared.identifier(for: loadableState, in: self)
    TaskStore.shared.tasks[identifier]?.cancel()
    setLoadingStateIfNeeded(on: loadableState, runSilently: runSilently)
    TaskStore.shared.tasks[identifier] = Task(priority: priority) {
      defer { TaskStore.shared.tasks[identifier] = nil }
      await runReturningTaskBody(loadableState, silently: runSilently, block: block)
    }

    return TaskStore.shared.tasks[identifier]!
  }

  @MainActor public func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool = false,
    block: @escaping () async throws -> Value
  ) async {
    setLoadingStateIfNeeded(on: loadableState, runSilently: runSilently)
    await runReturningTaskBody(loadableState, silently: runSilently, block: block)
  }

  @MainActor @discardableResult public func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool = false,
    priority: TaskPriority? = nil,
    block: @escaping (_ yield: (_ state: LoadableState<Value>) -> Void) async throws -> Void
  ) -> Task<Void, Never> {
    let identifier = TaskStore.shared.identifier(for: loadableState, in: self)
    TaskStore.shared.tasks[identifier]?.cancel()
    setLoadingStateIfNeeded(on: loadableState, runSilently: runSilently)
    TaskStore.shared.tasks[identifier] = Task(priority: priority) {
      defer { TaskStore.shared.tasks[identifier] = nil }
      await runYieldingTaskBody(loadableState, silently: runSilently, block: block)
    }

    return TaskStore.shared.tasks[identifier]!
  }

  @MainActor public func load<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool = false,
    block: @escaping (_ yield: (_ state: LoadableState<Value>) -> Void) async throws -> Void
  ) async {
    setLoadingStateIfNeeded(on: loadableState, runSilently: runSilently)
    await runYieldingTaskBody(loadableState, silently: runSilently, block: block)
  }

  @MainActor private func runReturningTaskBody<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool = false,
    block: @escaping () async throws -> Value
  ) async {
    do {
      self[keyPath: loadableState] = try await .loaded(block())
    } catch is CancellationError {
      // Task was cancelled. Don't change the state anymore
    } catch is CancelLoadable {
      self[keyPath: loadableState] = .absent
    } catch {
      self[keyPath: loadableState] = .error(error)
    }
  }

  @MainActor private func runYieldingTaskBody<Value>(
    _ loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    silently runSilently: Bool = false,
    block: @escaping (_ yield: (_ state: LoadableState<Value>) -> Void) async throws -> Void
  ) async {
    do {
      try await block { self[keyPath: loadableState] = $0 }
    } catch is CancellationError {
      // Task was cancelled. Don't change the state anymore
    } catch is CancelLoadable {
      self[keyPath: loadableState] = .absent
    } catch {
      self[keyPath: loadableState] = .error(error)
    }
  }

  @MainActor private func setLoadingStateIfNeeded<Value>(
    on loadableState: ReferenceWritableKeyPath<Self, LoadableState<Value>>,
    runSilently: Bool
  ) {
    if !runSilently {
      if case .loading = self[keyPath: loadableState] {} else {
        self[keyPath: loadableState] = .loading
      }
    }
  }
}
