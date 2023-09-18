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

/// A property wrapper that adds automatic state and `Task` management around a ``Processed/LoadableState``.
/// It takes care of creating a `Task` to load the resource, cancel any previous `Task` instances and setting
/// the appropriate loading states that are exposed through its ``wrappedValue``.
///
/// You can use this property wrapper in any SwiftUI view.
/// To start loading a resource, call one of the `load` methods of the `$`-prefixed synthesized property.
///
/// ```swift
///struct DemoView: View {
///  @Loadable<[Int]> var numbers
///
///  @MainActor func loadNumbers() {
///    $numbers.load {
///      try await fetchNumbers()
///    }
///  }
///
///  var body: some View {
///    List {
///      Button("Reload") { loadNumbers() }
///        .disabled(numbers.isLoading)
///      switch numbers {
///      case .absent:
///        EmptyView()
///      case .loading:
///        ProgressView()
///      case .error(let error):
///        Text("\(error.localizedDescription)")
///      case .loaded(let numbers):
///        ForEach(numbers, id: \.self) { number in
///          Text(String(number))
///        }
///      }
///    }
///  }
///}
/// ```
///
/// - Note: This is only meant to be used from within SwiftUI views.
/// If you need the same functionality from a class, please refer to ``Processed/LoadableSupport``.
@propertyWrapper public struct Loadable<Value>: DynamicProperty where Value: Sendable {
  
  @State private var state: LoadableState<Value>
  @State private var task: Task<Void, Never>?
  
  /// The current state of the loadable resource.
  ///
  /// It is okay to modify the state manually, instead of having it managed by a process like ``Processed/Loadable/Binding/load(silently:priority:block:)-4w49u``.
  /// However, doing so will cancel any ongoing task first, to prevent data races.
  @MainActor public var wrappedValue: LoadableState<Value> {
    get { state }
    nonmutating set {
      cancel()
      state = newValue
    }
  }

  /// Provides an interface for automatic control over the loading process,
  /// through a set of easy to use methods.
  ///
  /// Use the `$`-prefixed synthesized property to access these advanced controls.
  ///
  /// Example:
  ///
  /// ```swift
  /// @Loadable<[Int]> var numbers
  ///
  /// /* ... */
  ///
  /// $numbers.load {
  ///   try await fetchNumbers()
  /// }
  /// ```
  @MainActor public var projectedValue: Binding {
    .init(state: $state, task: $task)
  }
  
  public init(wrappedValue initialState: LoadableState<Value> = .absent) {
    self._state = .init(initialValue: initialState)
  }
  
  // MARK: - Manual Process Modifiers

  private func cancel() {
    task?.cancel()
    task = nil
  }
}

extension Loadable {
  /// An object providing an interface for automatic control over the loading process,
  /// through a set of easy to use methods.
  @propertyWrapper public struct Binding {
    @SwiftUI.Binding var state: LoadableState<Value>
    @SwiftUI.Binding var task: Task<Void, Never>?
    
    /// The current state of the loadable resource.
    ///
    /// It is okay to modify the state manually, instead of having it managed by a process like ``Processed/Loadable/Binding/load(silently:priority:block:)-4w49u``.
    /// However, doing so will cancel any ongoing task first, to prevent data races.
    public var wrappedValue: LoadableState<Value> {
      get { state }
      nonmutating set {
        cancel()
        state = newValue
      }
    }

    /// Provides an interface for automatic control over the loading process,
    /// through a set of easy to use methods.
    ///
    /// Use the `$`-prefixed synthesized property to access these advanced controls.
    ///
    /// Example:
    ///
    /// ```swift
    /// @Loadable<[Int]> var numbers
    ///
    /// /* ... */
    ///
    /// $numbers.load {
    ///   try await fetchNumbers()
    /// }
    /// ```
    public var projectedValue: Binding {
      self
    }

    /// An object providing an interface for automatic control over the loading process,
    /// through a set of easy to use methods.

    public init(
      state: SwiftUI.Binding<LoadableState<Value>>,
      task: SwiftUI.Binding<Task<Void, Never>?>
    ) {
      self._state = state
      self._task = task
    }

    /// An object providing an interface for automatic control over the loading process,
    /// through a set of easy to use methods.
    public init(_ binding: Loadable<Value>.Binding) {
      self = binding
    }

    /// Cancels the task of an ongoing resource loading process.
    ///
    /// - Note: You are responsible for cooperating with the task cancellation within the loading closures.
    public func cancel() {
      task?.cancel()
      task = nil
    }
    
    /// Cancels the task of an ongoing resource loading process and resets the state to `.absent`.
    ///
    /// - Note: You are responsible for cooperating with the task cancellation within the loading closures.
    public func reset() {
      if case .absent = state {} else {
        state = .absent
      }
      cancel()
    }

    private func setLoadingStateIfNeeded(runSilently: Bool) {
      if !runSilently {
        if case .loading = state {} else {
          state = .loading
        }
      }
    }

    // MARK: - Run Loadable With Yielding

    /// Starts a resource loading process in a new `Task` that continuously yields results
    /// until the `block` closure terminates or fails, while setting the ``Processed/LoadableState`` accordingly.
    ///
    /// At the start of this method, any previously created tasks managed by this type will be cancelled
    /// and the loading state will be set to `.loading`, unless `runSilently` is set to true.
    ///
    /// Throwing an error inside the `block` closure will cause a final `.error` state to be set.
    ///
    /// - Parameters:
    ///   - runSilently: If `true`, the state will not be set to `.loading` initially.
    ///   - priority: The priority level for the `Task` that is created and used for the loading process.
    ///   - block: The asynchronous block to run.
    ///   The block exposes a `yield` closure you can call to continuously update the resource loading state over time.
    ///
    /// - Returns: The task that runs the asynchronous loading process. You don't have to store it, but you can.
    @MainActor @discardableResult public func load(
      silently runSilently: Bool = false,
      priority: TaskPriority? = nil,
      block: @MainActor @escaping (_ yield: (_ state: LoadableState<Value>) -> Void) async throws -> Void
    ) -> Task<Void, Never> {
      cancel()
      setLoadingStateIfNeeded(runSilently: runSilently)
      let task = Task(priority: priority) {
        do {
          if !runSilently {
            if case .loading = state {} else {
              state = .loading
            }
          }
          try await block { yieldedState in
            state = yieldedState
          }
        } catch is CancellationError {
          // Task was cancelled. Don't change the state anymore
        } catch is CancelLoadable {
          cancel()
        } catch {
          state = .error(error)
        }
      }
      self.task = task
      return task
    }

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
    ///   - runSilently: If `true`, the state will not be set to `.loading` initially.
    ///   - block: The asynchronous block to run.
    ///   The block exposes a `yield` closure you can call to continuously update the resource loading state over time.
    @MainActor public func load(
      silently runSilently: Bool = false,
      block: @MainActor @escaping (_ yield: (_ state: LoadableState<Value>) -> Void) async throws -> Void
    ) async {
      cancel()
      setLoadingStateIfNeeded(runSilently: runSilently)
      do {
        try await block { yieldedState in
          state = yieldedState
        }
      } catch is CancellationError {
        // Task was cancelled. Don't change the state anymore
      } catch is CancelLoadable {
        cancel()
      } catch {
        state = .error(error)
      }
    }
    
    // MARK: - Run Loadable With Result
    
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
    ///   - runSilently: If `true`, the state will not be set to `.loading` initially.
    ///   - priority: The priority level for the `Task` that is created and used for the loading process.
    ///   - block: The asynchronous block to run.
    ///
    /// - Returns: The task that runs the asynchronous loading process. You don't have to store it, but you can.
    @MainActor @discardableResult public func load(
      silently runSilently: Bool = false,
      priority: TaskPriority? = nil,
      block: @MainActor @escaping () async throws -> Value
    ) -> Task<Void, Never> {
      cancel()
      setLoadingStateIfNeeded(runSilently: runSilently)
      let task = Task(priority: priority) {
        do {
          setLoadingStateIfNeeded(runSilently: runSilently)
          state = try await .loaded(block())
        } catch is CancellationError {
          // Task was cancelled. Don't change the state anymore
        } catch is CancelLoadable {
          cancel()
        } catch {
          state = .error(error)
        }
      }
      self.task = task
      return task
    }

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
    ///   - runSilently: If `true`, the state will not be set to `.loading` initially.
    ///   - block: The asynchronous block to run.
    @MainActor public func load(
      silently runSilently: Bool = false,
      block: @MainActor @escaping () async throws -> Value
    ) async {
      cancel()
      setLoadingStateIfNeeded(runSilently: runSilently)
      do {
        state = try await .loaded(block())
      } catch is CancellationError {
        // Task was cancelled. Don't change the state anymore
      } catch is CancelLoadable {
        cancel()
      } catch {
        state = .error(error)
      }
    }
  }
}

public typealias LoadableBinding<Value> = Loadable<Value>.Binding
