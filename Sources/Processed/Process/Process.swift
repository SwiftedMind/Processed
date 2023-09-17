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

/// A property wrapper to manage the state of an asynchronous process.
@propertyWrapper
public struct Process<ProcessID>: DynamicProperty where ProcessID: Equatable, ProcessID: Sendable {
  
  @SwiftUI.State private var state: ProcessState<ProcessID>
  @SwiftUI.State private var task: Task<Void, Never>?
  
  /// The current state of the process.
  public var wrappedValue: ProcessState<ProcessID> {
    get { state }
    nonmutating set {
      cancel()
      state = newValue
    }
  }
  
  /// Provides a binding for controlling the process.
  public var projectedValue: Binding {
    .init(state: $state, task: $task)
  }
  
  /// Initializes the process with an initial state.
  /// - Parameter initialState: The initial state of the process. Defaults to `.idle`.
  public init(initialState: ProcessState<ProcessID> = .idle) {
    self._state = .init(initialValue: initialState)
  }
  
  /// Default initializer for `Process<SingleProcess>`.
  public init() where ProcessID == SingleProcess {
    self._state = .init(initialValue: .idle)
  }
  
  /// Cancels any running task associated with this process.
  private func cancel() {
    task?.cancel()
    task = nil
  }
}

extension Process {
  /// A binding for controlling the process's state and execution.
  @propertyWrapper public struct Binding {
    @SwiftUI.Binding var state: ProcessState<ProcessID>
    @SwiftUI.Binding var task: Task<Void, Never>?
    
    public var wrappedValue: ProcessState<ProcessID> {
      get { state }
      nonmutating set {
        cancel()
        state = newValue
      }
    }
    
    /// Provides a binding for controlling the process.
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
    
    public static func mocked(
      _ container: ProcessMockContainer<ProcessID>
    ) -> Process<ProcessID>.Binding {
      .init(state: container.processBinding, task: container.taskBinding)
    }
    
    public static func mocked() -> Process<ProcessID>.Binding {
      let container = ProcessMockContainer<ProcessID>()
      return .init(state: container.processBinding, task: container.taskBinding)
    }
    
    public func cancel() {
      task?.cancel()
      task = nil
    }
    
    public func reset() {
      if case .idle = state {} else {
        state = .idle
      }
      cancel()
    }
    
    // MARK: - Run
    
    /// Runs a process with the provided asynchronous closure.
    /// - Parameters:
    ///   - process: The process to run.
    ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`.
    ///   - priority: The priority of the task.
    ///   - block: The asynchronous block of code to execute.
    /// - Returns: The task representing the process execution.
    @discardableResult public func run(
      _ process: ProcessID,
      silently runSilently: Bool = false,
      priority: TaskPriority? = nil,
      block: @escaping () async throws -> Void
    ) -> Task<Void, Never> {
      cancel()
      let task = Task(priority: priority) {
        await runTaskBody(process: process, runSilently: runSilently, block: block)
      }
      self.task = task
      return task
    }
    
    public func run(
      _ process: ProcessID,
      silently runSilently: Bool = false,
      block: @escaping () async throws -> Void
    ) async {
      await runTaskBody(process: process, runSilently: runSilently, block: block)
    }
    
    public func run(
      silently runSilently: Bool = false,
      block: @escaping () async throws -> Void
    ) where ProcessID == SingleProcess {
      run(.init(), silently: runSilently, block: block)
    }
    
    public func run(
      silently runSilently: Bool = false,
      block: @escaping () async throws -> Void
    ) async where ProcessID == SingleProcess {
      await runTaskBody(process: .init(), runSilently: runSilently, block: block)
    }
    
    // MARK: - Run Detached
    
    /// Runs a process with the provided asynchronous closure in a detached task.
    /// - Parameters:
    ///   - process: The process to run.
    ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`.
    ///   - priority: The priority of the task.
    ///   - block: The asynchronous block of code to execute.
    /// - Returns: The task representing the process execution.
    @discardableResult public func runDetached(
      _ process: ProcessID,
      silently runSilently: Bool = false,
      priority: TaskPriority? = nil,
      block: @escaping () async throws -> Void
    ) -> Task<Void, Never> {
      cancel()
      let task = Task.detached(priority: priority) {
        await runTaskBody(process: process, runSilently: runSilently, block: block)
      }
      self.task = task
      return task
    }
    
    public func runDetached(
      _ process: ProcessID,
      silently runSilently: Bool = false,
      block: @escaping () async throws -> Void
    ) async {
      await runDetached(process, silently: runSilently, block: block).value
    }
    
    public func runDetached(
      silently runSilently: Bool = false,
      block: @escaping () async throws -> Void
    ) where ProcessID == SingleProcess {
      runDetached(.init(), silently: runSilently, block: block)
    }
    
    public func runDetached(
      silently runSilently: Bool = false,
      block: @escaping () async throws -> Void
    ) async where ProcessID == SingleProcess {
      await runDetached(.init(), silently: runSilently, block: block).value
    }
    
    // MARK: - Internal
    
    private func runTaskBody(
      process: ProcessID,
      runSilently: Bool,
      block: @escaping () async throws -> Void
    ) async {
      do {
        if !runSilently {
          state = .running(process)
        }
        try await block()
        state = .finished(process)
      } catch is CancellationError {
        // Task was cancelled. Don't change the state anymore
      } catch is ProcessReset {
        cancel()
      } catch {
        state = .failed(process: process, error: error)
      }
    }
  }
}

public typealias ProcessBinding<SingleProcess: Equatable> = Process<SingleProcess>.Binding
