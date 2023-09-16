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

    @SwiftUI.State private var state: ProcessState<ProcessKind>
    @SwiftUI.State private var task: Task<Void, Never>?

    /// The current state of the process.
    public var wrappedValue: ProcessState<ProcessKind> {
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
    public init(initialState: ProcessState<ProcessKind> = .idle) {
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
        @Binding var state: ProcessState<ProcessKind>
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
        @discardableResult public func run(
            _ process: ProcessKind,
            silently runSilently: Bool = false,
            priority: TaskPriority? = nil,
            block: @escaping () async throws -> Void
        ) -> Task<Void, Never> {
            cancel(reset: false)
            let task = Task(priority: priority) {
                await runTaskBody(process: process, runSilently: runSilently, block: block)
            }
            self.task = task
            return task
        }

        public func run(
            _ process: ProcessKind,
            silently runSilently: Bool = false,
            block: @escaping () async throws -> Void
        ) async {
            await run(process, silently: runSilently, block: block).value
        }

        public func run(
            silently runSilently: Bool = false,
            block: @escaping () async throws -> Void
        ) where ProcessKind == UniqueProcessKind {
            run(.init(), silently: runSilently, block: block)
        }

        public func run(
            silently runSilently: Bool = false,
            block: @escaping () async throws -> Void
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
            } catch is ProcessReset {
                cancel()
            } catch {
                state = .failed(process: process, error: error)
            }
        }
    }
}
