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

/// A protocol that adds support for automatic state and `Task` management for ``Processed/ProcessState`` to the class.
///
/// The provided method takes care of creating a `Task` to run the process in, cancel any previous `Task` instances and setting
/// the appropriate loading states on the ``Processed/ProcessState`` that you specify.
///
/// To start a process, call one of the `run` methods on self with a key path to a ``Processed/ProcessState``
/// property.
///
/// ```swift
/// @MainActor final class ViewModel: ObservableObject, ProcessSupport {
///   @Published var numbers: ProcessState = .idle
///
///   func save() {
///     run {
///       return try await save()
///     }
///   }
/// }
/// ```
///
/// You can run different processes on the same state by providing a process identifier:
///
///  ```swift
/// @MainActor final class ViewModel: ObservableObject, ProcessSupport {
///   enum ProcessKind: Equatable {
///     case saving
///     case deleting
///   }
///
///   @Published var action: ProcessState<ProcessKind> = .idle
///
///   func save() {
///     run(\.action, as: .saving) {
///       return try await save()
///     }
///   }
///
///   func delete() {
///     run(\.action, as: .delete) {
///       return try await delete()
///     }
///   }
/// }
/// ```
///
/// - Note: This is only meant to be used in classes.
/// If you want to do this inside a SwiftUI view, please refer to the ``Processed/Process`` property wrapper.
public protocol ProcessSupport: AnyObject {

  /// Cancels the task of an ongoing process.
  ///
  /// - Note: You are responsible for cooperating with the task cancellation within the loading closures.
  @MainActor func cancel<ProcessID: Equatable>(_ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>)

  /// Cancels the task of an ongoing process and resets the state to `.idle`.
  ///
  /// - Note: You are responsible for cooperating with the task cancellation within the process closures.
  @MainActor func reset<ProcessID: Equatable>(_ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>)

  /// Starts a process in a new `Task`, waiting for a return value or thrown error from the
  /// `block` closure, while setting the ``Processed/ProcessState`` accordingly.
  ///
  /// At the start of this method, any previously created tasks managed by this type will be cancelled
  /// and the loading state will be set to `.running`, unless `runSilently` is set to true.
  ///
  /// Throwing an error inside the `block` closure will cause a final `.failed` state to be set,
  /// while a returned value will cause a final `.finished` state to be set.
  ///
  /// - Parameters:
  ///   - processState: The key path to the ``Processed/ProcessState``.
  ///   - process: The process to run.
  ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`, depending on the outcome of the `block` closure.
  ///   - priority: The priority of the task. Defaults to `nil`.
  ///   - block: The asynchronous block of code to execute.
  ///
  /// - Returns: The task representing the process execution.
  @MainActor @discardableResult func run<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
    as process: ProcessID,
    silently runSilently: Bool,
    priority: TaskPriority?,
    block: @MainActor @escaping () async throws -> Void
  ) -> Task<Void, Never>
  
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
  /// - Parameters:
  ///   - processState: The key path to the ``Processed/ProcessState``.
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
  @MainActor @discardableResult func run<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
    as process: ProcessID,
    silently runSilently: Bool,
    interrupts: [Duration],
    priority: TaskPriority?,
    block: @MainActor @escaping () async throws -> Void,
    onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
  ) -> Task<Void, Never>

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
  ///   - processState: The key path to the ``Processed/ProcessState``.
  ///   - process: The process to run.
  ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`, depending on the outcome of the `block` closure.
  ///   - block: The asynchronous block of code to execute.
  @MainActor func run<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
    as process: ProcessID,
    silently runSilently: Bool,
    block: @MainActor @escaping () async throws -> Void
  ) async
  
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
  ///   - processState: The key path to the ``Processed/ProcessState``.
  ///   - process: The process to run.
  ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`, depending on the outcome of the `block` closure.
  ///   - interrupts: An array of `Duration` values specifying the times at which the `onInterrupt` closure should be called.
  ///   These values are accumulating, i.e. passing an array of `[.seconds(1), .seconds(2)]` will cause the interrupt closure
  ///   to be called 1 second as well as 3 seconds after the process has started.
  ///   - block: The asynchronous block of code to execute.
  ///   - onInterrupt: A closure that will be called after the given delays in the `interrupts` array,
  ///   allowing you to perform actions like logging or modifying state during a long-running process, or set a timeout (by cancelling or resetting the process).
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @MainActor func run<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
    as process: ProcessID,
    silently runSilently: Bool,
    interrupts: [Duration],
    block: @MainActor @escaping () async throws -> Void,
    onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
  ) async
  
  /// Starts a process in a new `Task`, waiting for a return value or thrown error from the
  /// `block` closure, while setting the ``Processed/ProcessState`` accordingly.
  ///
  /// At the start of this method, any previously created tasks managed by this type will be cancelled
  /// and the loading state will be set to `.running`, unless `runSilently` is set to true.
  ///
  /// Throwing an error inside the `block` closure will cause a final `.failed` state to be set,
  /// while a returned value will cause a final `.finished` state to be set.
  ///
  /// - Parameters:
  ///   - processState: The key path to the ``Processed/ProcessState``.
  ///   - process: The process to run.
  ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`, depending on the outcome of the `block` closure.
  ///   - priority: The priority of the task. Defaults to `nil`.
  ///   - block: The asynchronous block of code to execute.
  ///
  /// - Returns: The task representing the process execution.
  @MainActor @discardableResult func run(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
    silently runSilently: Bool,
    priority: TaskPriority?,
    block: @MainActor @escaping () async throws -> Void
  ) -> Task<Void, Never>
  
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
  /// - Parameters:
  ///   - processState: The key path to the ``Processed/ProcessState``.
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
  @MainActor @discardableResult func run(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
    silently runSilently: Bool,
    interrupts: [Duration],
    priority: TaskPriority?,
    block: @MainActor @escaping () async throws -> Void,
    onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
  ) -> Task<Void, Never>
  
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
  ///   - processState: The key path to the ``Processed/ProcessState``.
  ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`, depending on the outcome of the `block` closure.
  ///   - block: The asynchronous block of code to execute.
  @MainActor func run(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
    silently runSilently: Bool,
    block: @MainActor @escaping () async throws -> Void
  ) async
  
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
  ///   - processState: The key path to the ``Processed/ProcessState``.
  ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`, depending on the outcome of the `block` closure.
  ///   - interrupts: An array of `Duration` values specifying the times at which the `onInterrupt` closure should be called.
  ///   These values are accumulating, i.e. passing an array of `[.seconds(1), .seconds(2)]` will cause the interrupt closure
  ///   to be called 1 second as well as 3 seconds after the process has started.
  ///   - block: The asynchronous block of code to execute.
  ///   - onInterrupt: A closure that will be called after the given delays in the `interrupts` array,
  ///   allowing you to perform actions like logging or modifying state during a long-running process, or set a timeout (by cancelling or resetting the process).
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @MainActor func run(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
    silently runSilently: Bool,
    interrupts: [Duration],
    block: @MainActor @escaping () async throws -> Void,
    onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
  ) async
}

// MARK: - Implementation

extension ProcessSupport {
  
  @MainActor public func cancel<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>
  ) {
    let identifier = TaskStore.shared.identifier(for: processState, in: self)
    TaskStore.shared.tasks[identifier]?.cancel()
    TaskStore.shared.tasks.removeValue(forKey: identifier)
  }

  @MainActor public func reset<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>
  ) {
    if case .idle = self[keyPath: processState] {} else {
      self[keyPath: processState] = .idle
    }
    cancel(processState)
  }

  @MainActor @discardableResult public func run<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
    as process: ProcessID,
    silently runSilently: Bool = false,
    priority: TaskPriority? = nil,
    block: @MainActor @escaping () async throws -> Void
  ) -> Task<Void, Never> {
    let identifier = TaskStore.shared.identifier(for: processState, in: self)
    TaskStore.shared.tasks[identifier]?.cancel()
    setRunningStateIfNeeded(on: processState, process: process, runSilently: runSilently)
    TaskStore.shared.tasks[identifier] = Task(priority: priority) {
      defer { TaskStore.shared.tasks[identifier] = nil }
      await runTaskBody(
        processState,
        process: process,
        silently: runSilently,
        block: block
      )
    }

    return TaskStore.shared.tasks[identifier]!
  }
  
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @MainActor @discardableResult public func run<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
    as process: ProcessID,
    silently runSilently: Bool = false,
    interrupts: [Duration],
    priority: TaskPriority? = nil,
    block: @MainActor @escaping () async throws -> Void,
    onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
  ) -> Task<Void, Never> {
    let identifier = TaskStore.shared.identifier(for: processState, in: self)
    TaskStore.shared.tasks[identifier]?.cancel()
    setRunningStateIfNeeded(on: processState, process: process, runSilently: runSilently)
    TaskStore.shared.tasks[identifier] = Task(priority: priority) {
      defer { TaskStore.shared.tasks[identifier] = nil }
      await runTaskBody(
        processState,
        process: process,
        silently: runSilently,
        interrupts: interrupts,
        block: block,
        onInterrupt: onInterrupt
      )
    }

    return TaskStore.shared.tasks[identifier]!
  }
  
  @MainActor public func run<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
    as process: ProcessID,
    silently runSilently: Bool = false,
    block: @MainActor @escaping () async throws -> Void
  ) async {
    setRunningStateIfNeeded(on: processState, process: process, runSilently: runSilently)
    await runTaskBody(processState, process: process, silently: runSilently, block: block)
  }
  
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @MainActor public func run<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
    as process: ProcessID,
    silently runSilently: Bool = false,
    interrupts: [Duration],
    block: @MainActor @escaping () async throws -> Void,
    onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
  ) async {
    setRunningStateIfNeeded(on: processState, process: process, runSilently: runSilently)
    await runTaskBody(
      processState,
      process: process,
      silently: runSilently,
      interrupts: interrupts,
      block: block,
      onInterrupt: onInterrupt
    )
  }
  
  @MainActor @discardableResult public func run(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
    silently runSilently: Bool = false,
    priority: TaskPriority? = nil,
    block: @MainActor @escaping () async throws -> Void
  ) -> Task<Void, Never> {
    run(
      processState,
      as: .init(),
      silently: runSilently,
      priority: priority,
      block: block
    )
  }
  
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @MainActor @discardableResult public func run(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
    silently runSilently: Bool = false,
    interrupts: [Duration],
    priority: TaskPriority? = nil,
    block: @MainActor @escaping () async throws -> Void,
    onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
  ) -> Task<Void, Never> {
    run(
      processState,
      as: .init(),
      silently: runSilently,
      interrupts: interrupts,
      priority: priority,
      block: block,
      onInterrupt: onInterrupt
    )
  }
  
  @MainActor public func run(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
    silently runSilently: Bool = false,
    block: @MainActor @escaping () async throws -> Void
  ) async {
    await run(
      processState,
      as: .init(),
      silently: runSilently,
      block: block
    )
  }
  
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @MainActor public func run(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
    silently runSilently: Bool = false,
    interrupts: [Duration],
    block: @MainActor @escaping () async throws -> Void,
    onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
  ) async {
    await run(
      processState,
      as: .init(),
      silently: runSilently,
      interrupts: interrupts,
      block: block,
      onInterrupt: onInterrupt
    )
  }

  @MainActor private func runTaskBody<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
    process: ProcessID,
    silently runSilently: Bool = false,
    block: @MainActor @escaping () async throws -> Void
  ) async {
    do {
      try await block()
      self[keyPath: processState] = .finished(process)
    } catch is CancellationError {
      // Task was cancelled. Don't change the state anymore
    } catch is CancelProcess {
      cancel(processState)
    } catch is ResetProcess {
      reset(processState)
    } catch {
      self[keyPath: processState] = .failed(process: process, error: error)
    }
  }

  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @MainActor private func runTaskBody<ProcessID: Equatable>(
    _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
    process: ProcessID,
    silently runSilently: Bool = false,
    interrupts: [Duration],
    block: @MainActor @escaping () async throws -> Void,
    onInterrupt: @MainActor @escaping (_ accumulatedDelay: Duration) throws -> Void
  ) async {
    do {
      try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
          try await block()
          self[keyPath: processState] = .finished(process)
        }
        
        group.addTask {
          var accumulatedDelay: Duration = .zero
          for delay in interrupts {
            try await Task.sleep(for: delay)
            accumulatedDelay += delay
            try await onInterrupt(accumulatedDelay)
          }

          // When all interruptions are processed, throw a special error
          throw InterruptionsDoneError()
        }
        
        do {
          try await group.next()
          // Here, the block() Task has finished, so we can cancel the interruptions
          group.cancelAll()
        } catch is InterruptionsDoneError {
          // In this case, the interruptions are processed and we can wair for the block() Task to finish
          try await group.next()
        }
      }
    } catch is CancellationError {
      // Task was cancelled. Don't change the state anymore
    } catch is CancelProcess {
      cancel(processState)
    } catch is ResetProcess {
      reset(processState)
    } catch {
      self[keyPath: processState] = .failed(process: process, error: error)
    }
  }

  @MainActor private func setRunningStateIfNeeded<ProcessID: Equatable>(
    on processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
    process: ProcessID,
    runSilently: Bool
  ) {
    if !runSilently {
      if case .running(let runningProcess) = self[keyPath: processState], runningProcess == process {} else {
        self[keyPath: processState] = .running(process)
      }
    }
  }
}
