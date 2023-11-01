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

/// A property wrapper that adds automatic state and `Task` management around a ``Processed/ProcessState``.
/// It takes care of creating a `Task` to run the process in, cancel any previous `Task` instances and setting
/// the appropriate loading states that are exposed through its ``wrappedValue``.
///
/// You can use this property wrapper in any SwiftUI view.
/// To start loading a resource, call one of the `run` methods of the `$`-prefixed synthesized property.
///
/// ```swift
/// struct DemoView: View {
///   @Process var saving
///
///   @MainActor func save() {
///     $saving.run {
///       try await save()
///     }
///   }
///
///   var body: some View {
///     List {
///       Button("Save") { save() }
///         .disabled(numbers.isLoading)
///       switch saving {
///       case .idle:
///         Text("Idle")
///       case .running:
///         Text("Saving")
///       case .failed(_, let error):
///         Text("\(error.localizedDescription)")
///       case .finished:
///         Text("Finished Saving")
///       }
///     }
///   }
/// }
/// ```
///
/// - Note: This is only meant to be used from within SwiftUI views.
/// If you need the same functionality from a class, please refer to ``Processed/ProcessSupport``.
@propertyWrapper public struct Process<ProcessID>: DynamicProperty where ProcessID: Equatable, ProcessID: Sendable {

  @SwiftUI.State private var state: ProcessState<ProcessID>
  @SwiftUI.State private var task: Task<Void, Never>?
  
  /// The current state of the process.
  ///
  /// It is okay to modify the state manually, instead of having it managed by a process like ``Processed/Process/Binding/run(silently:block:)-5h20w``.
  /// However, doing so will cancel any ongoing task first, to prevent data races.
  @MainActor public var wrappedValue: ProcessState<ProcessID> {
    get { state }
    nonmutating set {
      cancel()
      state = newValue
    }
  }
  
  /// Provides an interface for automatic control over the process state,
  /// through a set of easy to use methods.
  ///
  /// Use the `$`-prefixed synthesized property to access these advanced controls.
  ///
  /// Example:
  ///
  /// ```swift
  /// @Process var saving
  /// /* ... */
  /// $saving.run {
  ///   try await save()
  /// }
  /// ```
  ///
  /// You can run different processes on the same state by providing a process identifier:
  ///
  /// ```swift
  /// enum ProcessKind: Equatable {
  ///   case saving
  ///   case deleting
  /// }
  ///
  /// @Process<ProcessKind> var action
  /// /* ... */
  /// $action.run(.saving) {
  ///   try await save()
  /// }
  /// $action.run(.deleting) {
  ///   try await delete()
  /// }
  /// ```
  @MainActor public var projectedValue: Binding {
    .init(state: $state, task: $task)
  }
  
  /// Initializes the process with an initial state.
  /// - Parameter initialState: The initial state of the process. Defaults to `.idle`.
  public init(wrappedValue initialState: ProcessState<ProcessID> = .idle) {
    self._state = .init(initialValue: initialState)
  }

  /// Default initializer for `Process<SingleProcess>`.
  public init(wrappedValue initialState: ProcessState<ProcessID> = .idle) where ProcessID == SingleProcess {
    self._state = .init(initialValue: .idle)
  }

  /// Cancels any running task associated with this process.
  private func cancel() {
    task?.cancel()
    task = nil
  }
}

extension Process {
  /// An object providing an interface for automatic control over the loading process,
  /// through a set of easy to use methods.
  @propertyWrapper public struct Binding {
    @SwiftUI.Binding var state: ProcessState<ProcessID>
    @SwiftUI.Binding var task: Task<Void, Never>?
    
    /// The current state of the process.
    ///
    /// It is okay to modify the state manually, instead of having it managed by a process like ``Processed/Process/Binding/run(silently:block:)-5h20w``.
    /// However, doing so will cancel any ongoing task first, to prevent data races.
    public var wrappedValue: ProcessState<ProcessID> {
      get { state }
      nonmutating set {
        cancel()
        state = newValue
      }
    }
    
    /// Provides an interface for automatic control over the process state,
    /// through a set of easy to use methods.
    ///
    /// Use the `$`-prefixed synthesized property to access these advanced controls.
    ///
    /// Example:
    ///
    /// ```swift
    /// @Process var saving
    /// /* ... */
    /// $saving.run {
    ///   try await save()
    /// }
    /// ```
    ///
    /// You can run different processes on the same state by providing a process identifier:
    ///
    /// ```swift
    /// enum ProcessKind: Equatable {
    ///   case saving
    ///   case deleting
    /// }
    ///
    /// @Process<ProcessKind> var action
    /// /* ... */
    /// $action.run(.saving) {
    ///   try await save()
    /// }
    /// $action.run(.deleting) {
    ///   try await delete()
    /// }
    /// ```
    public var projectedValue: Binding {
      self
    }
    
    public init(
      state: SwiftUI.Binding<ProcessState<ProcessID>>,
      task: SwiftUI.Binding<Task<Void, Never>?>
    ) {
      self._state = state
      self._task = task
    }
    
    public init(_ binding: Process<ProcessID>.Binding) {
      self = binding
    }
    
    /// Cancels the task of an ongoing process.
    ///
    /// - Note: You are responsible for cooperating with the task cancellation within the loading closures.
    public func cancel() {
      task?.cancel()
      task = nil
    }

    /// Cancels the task of an ongoing process and resets the state to `.idle`.
    ///
    /// - Note: You are responsible for cooperating with the task cancellation within the process closures.
    public func reset() {
      if case .idle = state {} else {
        state = .idle
      }
      cancel()
    }

    private func setRunningStateIfNeeded(runSilently: Bool, process: ProcessID) {
      if !runSilently {
        if case .running(let runningProcess) = state, runningProcess == process {} else {
          state = .running(process)
        }
      }
    }

    // MARK: - Run
    
    /// Starts a process in a new `Task`, waiting for a return value or thrown error from the
    /// `block` closure, while setting the ``Processed/ProcessState`` accordingly.
    ///
    /// At the start of this method, any previously created tasks managed by this type will be cancelled
    /// and the loading state will be set to `.running`, unless `runSilently` is set to true.
    ///
    /// Throwing an error inside the `block` closure will cause a final `.failed` state to be set,
    /// while a returned value will cause a final `.finished` state to be set.
    ///
    /// - Important: It is your responsibility to cancel the loading process by calling ``Processed/Process/Binding/cancel()``
    ///  or ``Processed/Process/Binding/reset()``. If you want automated task cancellation when the SwiftUI view disappears,
    ///  call the `async` variant of ``Processed/Process/Binding/run(silently:block:)-5h20w`` from within a `.task` view modifier.
    ///
    /// - Parameters:
    ///   - process: The process to run.
    ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`, depending on the outcome of the `block` closure.
    ///   - priority: The priority of the task. Defaults to `nil`.
    ///   - block: The asynchronous block of code to execute.
    ///
    /// - Returns: The task representing the process execution.
    @MainActor @discardableResult public func run(
      _ process: ProcessID,
      silently runSilently: Bool = false,
      priority: TaskPriority? = nil,
      block: @MainActor @escaping () async throws -> Void
    ) -> Task<Void, Never> {
      cancel()
      setRunningStateIfNeeded(runSilently: runSilently, process: process)
      let task = Task(priority: priority) {
        await runTaskBody(process: process, runSilently: runSilently, block: block)
      }
      self.task = task
      return task
    }
    
    /// Starts a process in a new `Task`, waiting for a return value or thrown error from the
    /// `block` closure, while setting the ``Processed/ProcessState`` accordingly.
    /// This method also allows for handling interruptions at specified durations.
    ///
    /// At the start of this method, any previously created tasks managed by this type will be cancelled
    /// and the loading state will be set to `.running`, unless `runSilently` is set to true.
    ///
    /// Throwing an error inside the `block` closure will cause a final `.failed` state to be set,
    /// while a returned value will cause a final `.finished` state to be set.
    ///
    /// - Important: It is your responsibility to cancel the loading process by calling ``Processed/Process/Binding/cancel()``
    ///  or ``Processed/Process/Binding/reset()``. If you want automated task cancellation when the SwiftUI view disappears,
    ///  call the `async` variant of ``Processed/Process/Binding/run(silently:block:)-5h20w`` from within a `.task` view modifier.
    ///
    /// - Parameters:
    ///   - process: The process to run.
    ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`, depending on the outcome of the `block` closure.
    ///   - priority: The priority of the task. Defaults to `nil`.
    ///   - interrupts: An array of `Duration` values specifying the times at which the `onInterrupt` closure should be called.
    ///   These values are accumulating, i.e. passing an array of `[.seconds(1), .seconds(2)]` will cause the interrupt closure
    ///   to be called 1 second as well as 3 seconds after the process has started.
    ///   - block: The asynchronous block of code to execute.
    ///   - onInterrupt: A closure that will be called after the given delays in the `interrupts` array,
    ///   allowing you to perform actions like logging or modifying state during a long-running process, or set a timeout (by cancelling or resetting the process).
    ///
    /// - Returns: The task representing the process execution.
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    @MainActor @discardableResult public func run(
      _ process: ProcessID,
      silently runSilently: Bool = false,
      interrupts: [Duration],
      priority: TaskPriority? = nil,
      block: @MainActor @escaping () async throws -> Void,
      onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
    ) -> Task<Void, Never> {
      cancel()
      setRunningStateIfNeeded(runSilently: runSilently, process: process)
      let task = Task(priority: priority) {
        await runTaskBody(
          process: process,
          runSilently: runSilently,
          interrupts: interrupts,
          block: block,
          onInterrupt: onInterrupt
        )
      }
      self.task = task
      return task
    }
    
    /// Starts a process in the current asynchronous context, waiting for a return value or thrown error from the
    /// `block` closure, while setting the ``Processed/ProcessState`` accordingly.
    ///
    /// This method does not create its own `Task`, so you must `await` its completion.
    ///
    /// At the start of this method, any previously created tasks managed by this type will be cancelled
    /// and the loading state will be set to `.running`, unless `runSilently` is set to true.
    ///
    /// Throwing an error inside the `block` closure will cause a final `.failed` state to be set,
    /// while a returned value will cause a final `.finished` state to be set.
    ///
    /// - Parameters:
    ///   - process: The process to run.
    ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either
    ///   `.finished` or `.failed`, depending on the outcome of the `block` closure.
    ///   - block: The asynchronous block of code to execute.
    @MainActor public func run(
      _ process: ProcessID,
      silently runSilently: Bool = false,
      block: @MainActor @escaping () async throws -> Void
    ) async {
      cancel()
      setRunningStateIfNeeded(runSilently: runSilently, process: process)
      await runTaskBody(process: process, runSilently: runSilently, block: block)
    }
    
    /// Starts a process in the current asynchronous context, waiting for a return value or thrown error from the
    /// `block` closure, while setting the ``Processed/ProcessState`` accordingly.
    /// This method also allows for handling interruptions at specified durations.
    ///
    /// At the start of this method, any previously created tasks managed by this type will be cancelled
    /// and the loading state will be set to `.running`, unless `runSilently` is set to true.
    ///
    /// Throwing an error inside the `block` closure will cause a final `.failed` state to be set,
    /// while a returned value will cause a final `.finished` state to be set.
    ///
    /// - Parameters:
    ///   - process: The process to run.
    ///   - runSilently: If set to `true`, the `.running` state will be skipped, and the process will directly go to either `.finished` or `.failed`,
    ///   depending on the outcome of the `block` closure.
    ///   - interrupts: An array of `Duration` values specifying the times at which the `onInterrupt` closure should be called.
    ///   These values are accumulating, i.e. passing an array of `[.seconds(1), .seconds(2)]` will cause the interrupt closure
    ///   to be called 1 second as well as 3 seconds after the process has started.
    ///   - block: The asynchronous block of code to execute.
    ///   - onInterrupt: A closure that will be called after the given delays in the `interrupts` array,
    ///   allowing you to perform actions like logging or modifying state during a long-running process, or set a timeout (by cancelling or resetting the process).
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    @MainActor public func run(
      _ process: ProcessID,
      silently runSilently: Bool = false,
      interrupts: [Duration],
      block: @MainActor @escaping () async throws -> Void,
      onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
    ) async {
      cancel()
      setRunningStateIfNeeded(runSilently: runSilently, process: process)
      await runTaskBody(
        process: process,
        runSilently: runSilently,
        interrupts: interrupts,
        block: block,
        onInterrupt: onInterrupt
      )
    }
    
    /// Starts a process in a new `Task`, waiting for a return value or thrown error from the
    /// `block` closure, while setting the ``Processed/ProcessState`` accordingly.
    ///
    /// At the start of this method, any previously created tasks managed by this type will be cancelled
    /// and the loading state will be set to `.running`, unless `runSilently` is set to true.
    ///
    /// Throwing an error inside the `block` closure will cause a final `.failed` state to be set,
    /// while a returned value will cause a final `.finished` state to be set.
    ///
    /// - Important: It is your responsibility to cancel the loading process by calling ``Processed/Process/Binding/cancel()``
    ///  or ``Processed/Process/Binding/reset()``. If you want automated task cancellation when the SwiftUI view disappears,
    ///  call the `async` variant of ``Processed/Process/Binding/run(_:silently:block:)`` from within a `.task` view modifier.
    ///
    /// - Parameters:
    ///   - process: The process to run.
    ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`, depending on the outcome of the `block` closure.
    ///   - priority: The priority of the task. Defaults to `nil`.
    ///   - block: The asynchronous block of code to execute.
    ///
    /// - Returns: The task representing the process execution.
    @MainActor @discardableResult public func run(
      silently runSilently: Bool = false,
      block: @MainActor @escaping () async throws -> Void
    ) -> Task<Void, Never> where ProcessID == SingleProcess {
      run(.init(), silently: runSilently, block: block)
    }
    
    /// Starts a process in a new `Task`, waiting for a return value or thrown error from the
    /// `block` closure, while setting the ``Processed/ProcessState`` accordingly.
    /// This method also allows for handling interruptions at specified durations.
    ///
    /// At the start of this method, any previously created tasks managed by this type will be cancelled
    /// and the loading state will be set to `.running`, unless `runSilently` is set to true.
    ///
    /// Throwing an error inside the `block` closure will cause a final `.failed` state to be set,
    /// while a returned value will cause a final `.finished` state to be set.
    ///
    /// - Important: It is your responsibility to cancel the loading process by calling ``Processed/Process/Binding/cancel()``
    ///  or ``Processed/Process/Binding/reset()``. If you want automated task cancellation when the SwiftUI view disappears,
    ///  call the `async` variant of ``Processed/Process/Binding/run(_:silently:block:)`` from within a `.task` view modifier.
    ///
    /// - Parameters:
    ///   - process: The process to run.
    ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`, depending on the outcome of the `block` closure.
    ///   - priority: The priority of the task. Defaults to `nil`.
    ///   - interrupts: An array of `Duration` values specifying the times at which the `onInterrupt` closure should be called.
    ///   These values are accumulating, i.e. passing an array of `[.seconds(1), .seconds(2)]` will cause the interrupt closure
    ///   to be called 1 second as well as 3 seconds after the process has started.
    ///   - block: The asynchronous block of code to execute.
    ///   - onInterrupt: A closure that will be called after the given delays in the `interrupts` array,
    ///   allowing you to perform actions like logging or modifying state during a long-running process, or set a timeout (by cancelling or resetting the process).
    ///
    /// - Returns: The task representing the process execution.
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    @MainActor @discardableResult public func run(
      silently runSilently: Bool = false,
      interrupts: [Duration],
      priority: TaskPriority? = nil,
      block: @MainActor @escaping () async throws -> Void,
      onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
    ) -> Task<Void, Never> where ProcessID == SingleProcess {
      run(
        .init(),
        silently: runSilently,
        interrupts: interrupts,
        priority: priority,
        block: block,
        onInterrupt: onInterrupt
      )
    }
    
    /// Starts a process in the current asynchronous context, waiting for a return value or thrown error from the
    /// `block` closure, while setting the ``Processed/ProcessState`` accordingly.
    ///
    /// This method does not create its own `Task`, so you must `await` its completion.
    ///
    /// At the start of this method, any previously created tasks managed by this type will be cancelled
    /// and the loading state will be set to `.running`, unless `runSilently` is set to true.
    ///
    /// Throwing an error inside the `block` closure will cause a final `.failed` state to be set,
    /// while a returned value will cause a final `.finished` state to be set.
    ///
    /// - Parameters:
    ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`, depending on the outcome of the `block` closure.
    ///   - block: The asynchronous block of code to execute.
    @MainActor public func run(
      silently runSilently: Bool = false,
      block: @MainActor @escaping () async throws -> Void
    ) async where ProcessID == SingleProcess {
      await run(.init(), silently: runSilently, block: block)
    }
    
    /// Starts a process in the current asynchronous context, waiting for a return value or thrown error from the
    /// `block` closure, while setting the ``Processed/ProcessState`` accordingly.
    /// This method also allows for handling interruptions at specified durations.
    ///
    /// This method does not create its own `Task`, so you must `await` its completion.
    ///
    /// At the start of this method, any previously created tasks managed by this type will be cancelled
    /// and the loading state will be set to `.running`, unless `runSilently` is set to true.
    ///
    /// Throwing an error inside the `block` closure will cause a final `.failed` state to be set,
    /// while a returned value will cause a final `.finished` state to be set.
    ///
    /// - Parameters:
    ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either
    ///   `.finished` or `.failed`, depending on the outcome of the `block` closure.
    ///   - interrupts: An array of `Duration` values specifying the times at which the `onInterrupt` closure should be called.
    ///   These values are accumulating, i.e. passing an array of `[.seconds(1), .seconds(2)]` will cause the interrupt closure
    ///   to be called 1 second as well as 3 seconds after the process has started.
    ///   - block: The asynchronous block of code to execute.
    ///   - onInterrupt: A closure that will be called after the given delays in the `interrupts` array,
    ///   allowing you to perform actions like logging or modifying state during a long-running process, or set a timeout (by cancelling or resetting the process).
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    @MainActor public func run(
      silently runSilently: Bool = false,
      interrupts: [Duration],
      block: @MainActor @escaping () async throws -> Void,
      onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
    ) async where ProcessID == SingleProcess {
      await run(.init(), silently: runSilently, interrupts: interrupts, block: block, onInterrupt: onInterrupt)
    }
    
    // MARK: - Internal
    
    @MainActor private func runTaskBody(
      process: ProcessID,
      runSilently: Bool,
      block: @MainActor @escaping () async throws -> Void
    ) async {
      do {
        try await block()
        state = .finished(process)
      } catch is CancellationError {
        // Task was cancelled. Don't change the state anymore
      } catch is CancelProcess {
        cancel()
      } catch is ResetProcess {
        reset()
      } catch {
        state = .failed(process: process, error: error)
      }
    }
    
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    @MainActor private func runTaskBody(
      process: ProcessID,
      runSilently: Bool,
      interrupts: [Duration],
      block: @MainActor @escaping () async throws -> Void,
      onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
    ) async {
      do {
        try await withThrowingTaskGroup(of: Void.self) { group in
          group.addTask {
            try await block()
            state = .finished(process)
          }
          
          group.addTask {
            var accumulatedDelay: Duration = .zero
            for delay in interrupts {
              try await Task.sleep(for: delay)
              accumulatedDelay += delay
              try await onInterrupt(accumulatedDelay)
            }
          }
          
          try await group.next()
          group.cancelAll()
        }
      } catch is CancellationError {
        // Task was cancelled. Don't change the state anymore
      } catch is CancelProcess {
        cancel()
      } catch {
        state = .failed(process: process, error: error)
      }
    }
  }
}

/// An object providing an interface for automatic control over the loading process,
/// through a set of easy to use methods.
public typealias ProcessBinding<SingleProcess: Equatable> = Process<SingleProcess>.Binding
