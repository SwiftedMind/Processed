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

/// A unique identifier for a process.
public struct UniqueProcessKind: Equatable, Sendable {
    /// The unique identifier for the process.
    var processId: UUID
    /// The date when the process was initialized.
    var initializedAt: Date

    /// Initializes a new unique process.
    /// - Parameters:
    ///   - processId: The unique identifier for the process. Defaults to a new UUID.
    ///   - initializedAt: The date when the process was initialized. Defaults to current date and time.
    public init(processId: UUID = .init(), initializedAt: Date = .now) {
        self.processId = processId
        self.initializedAt = initializedAt
    }
}

/// A property wrapper to manage the state of an asynchronous process.
@propertyWrapper
public struct Process<ProcessKind>: DynamicProperty where ProcessKind: Equatable, ProcessKind: Sendable {

    /// Represents the possible states of a process.
    public enum State {
        case idle
        case running(ProcessKind)
        case failed(process: ProcessKind, error: Swift.Error)
        case finished(ProcessKind)
    }

    @SwiftUI.State private var state: State
    @SwiftUI.State private var task: Task<Void, Never>?

    /// The current state of the process.
    public var wrappedValue: State {
        get { state }
        nonmutating set {
            cancel()
            state = newValue
        }
    }

    /// Provides a manager for controlling the process.
    public var projectedValue: Manager {
        .init(state: $state, task: $task)
    }

    /// Initializes the process with an initial state.
    /// - Parameter initialState: The initial state of the process. Defaults to `.idle`.
    public init(initialState: State = .idle) {
        self._state = .init(initialValue: initialState)
    }

    /// Default initializer for `Process<UniqueProcessKind>`.
    public init() where ProcessKind == UniqueProcessKind {
        self._state = .init(initialValue: .idle)
    }

    /// Cancels any running task associated with this process.
    private func cancel() {
        task?.cancel()
        task = nil
    }
}

extension Process {
    /// A manager for controlling the process's state and execution.
    public struct Manager {
        @Binding var state: State
        @Binding var task: Task<Void, Never>?

        /// Cancels the ongoing process and its underlying task, if there is one, and optionally resets the process state to idle.
        /// - Parameter reset: Whether to reset the process state to `.idle`. Defaults to `true`.
        public func cancel(reset: Bool = true) {
            if reset { 
                if case .idle = state {} else {
                    state = .idle
                }
            }
            task?.cancel()
            task = nil
        }

        // MARK: - Run

        /// Runs a process with the provided asynchronous closure.
        /// - Parameters:
        ///   - process: The process to run.
        ///   - runSilently: If set to `true`, the `.running` state will be skipped and the process will directly go to either `.finished` or `.failed`.
        ///   - priority: The priority of the task.
        ///   - block: The asynchronous block of code to execute.
        /// - Returns: The task representing the process execution.
        @MainActor @discardableResult public func run(
            _ process: ProcessKind,
            silently runSilently: Bool = false,
            priority: TaskPriority? = nil,
            block: @MainActor @escaping () async throws -> Void
        ) -> Task<Void, Never> {
            cancel(reset: false)
            let task = Task(priority: priority) {
                await runTaskBody(process: process, runSilently: runSilently, block: block)
            }
            self.task = task
            return task
        }

        @MainActor public func run(
            _ process: ProcessKind,
            silently runSilently: Bool = false,
            block: @MainActor @escaping () async throws -> Void
        ) async {
            await run(process, silently: runSilently, block: block).value
        }

        @MainActor public func run(
            silently runSilently: Bool = false,
            block: @MainActor @escaping () async throws -> Void
        ) where ProcessKind == UniqueProcessKind {
            run(.init(), silently: runSilently, block: block)
        }

        @MainActor public func run(
            silently runSilently: Bool = false,
            block: @MainActor @escaping () async throws -> Void
        ) async where ProcessKind == UniqueProcessKind {
            await run(.init(), silently: runSilently, block: block).value
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
            _ process: ProcessKind,
            silently runSilently: Bool = false,
            priority: TaskPriority? = nil,
            block: @escaping () async throws -> Void
        ) -> Task<Void, Never> {
            cancel(reset: false)
            let task = Task.detached(priority: priority) {
                await runTaskBody(process: process, runSilently: runSilently, block: block)
            }
            self.task = task
            return task
        }

        public func runDetached(
            _ process: ProcessKind,
            silently runSilently: Bool = false,
            block: @escaping () async throws -> Void
        ) async {
            await runDetached(process, silently: runSilently, block: block).value
        }

        public func runDetached(
            silently runSilently: Bool = false,
            block: @escaping () async throws -> Void
        ) where ProcessKind == UniqueProcessKind {
            runDetached(.init(), silently: runSilently, block: block)
        }

         public func runDetached(
            silently runSilently: Bool = false,
            block: @escaping () async throws -> Void
        ) async where ProcessKind == UniqueProcessKind {
            await runDetached(.init(), silently: runSilently, block: block).value
        }

        // MARK: - Internal

        private func runTaskBody(
            process: ProcessKind,
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
            } catch is AbortError {
                cancel()
            } catch {
                state = .failed(process: process, error: error)
            }
        }
    }
}

extension Process.State {

    // MARK: - Reset

    /// Resets the state to `.idle`.
    public mutating func reset() {
        self = .idle
    }

    // MARK: - Start

    /// Starts running the specified process.
    /// - Parameter process: The process to start running.
    public mutating func start(_ process: ProcessKind) {
        self = .running(process)
    }

    /// Starts running a new unique process.
    public mutating func start() where ProcessKind == UniqueProcessKind {
        start(.init())
    }

    // MARK: - Finish

    /// Finishes the currently running process.
    public mutating func finish() {
        guard case .running(let process) = self else {
            return
        }

        self = .finished(process)
    }

    // MARK: - Fail

    /// Sets the state to `.failed` with the specified error.
    /// - Parameter error: The error causing the failure.
    public mutating func fail(with error: Swift.Error) {
        guard case .running(let process) = self else {
            return
        }

        self = .failed(process: process, error: error)
    }

    // MARK: - Manual Control

    /// Sets the process state to `idle`.
    public mutating func setIdle() {
        self = .idle
    }

    /// Sets the process state to `.failed` with the specified process and error.
    /// - Parameters:
    ///   - process: The process that failed.
    ///   - error: The error causing the failure.
    public mutating func setFailed(_ process: ProcessKind, error: Swift.Error) {
        self = .failed(process: process, error: error)
    }

    /// Sets the process state to `.finished` with the specified process.
    /// - Parameter process: The process that finished.
    public mutating func setFinished(_ process: ProcessKind) {
        self = .finished(process)
    }

    // MARK: - Convenience

    public var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    public var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    public func isRunning(_ process: ProcessKind) -> Bool {
        if case .running(let runningProcess) = self { return runningProcess == process }
        return false
    }

    public var hasFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    public func hasFailed(_ process: ProcessKind) -> Bool {
        if case .failed(let failedProcess, _) = self { return failedProcess == process }
        return false
    }

    public var error: Error? {
        if case .failed(_, let error) = self { return error }
        return nil
    }

    public var hasFinished: Bool {
        if case .finished = self { return true }
        return false
    }

    public func hasFinished(_ process: ProcessKind) -> Bool {
        if case .finished(let finishedProcess) = self { return finishedProcess == process }
        return false
    }
}

extension Process.State: Equatable {
    nonisolated public static func == (lhs: Process<ProcessKind>.State, rhs: Process<ProcessKind>.State) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.running(let leftId), .running(let rightId)): return leftId == rightId
        case (.failed(let leftId, _), .failed(let rightId, _)): return leftId == rightId
        case (.finished(let leftId), .finished(let rightId)): return leftId == rightId
        default: return false
        }
    }
}
