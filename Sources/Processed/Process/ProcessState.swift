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

/// Represents the possible states of a process.
public enum ProcessState<ProcessKind> {
    case idle
    case running(ProcessKind)
    case failed(process: ProcessKind, error: Swift.Error)
    case finished(ProcessKind)

    public init(initialState: ProcessState) {
        self = initialState
    }

    public init(initialState: ProcessState) where ProcessKind == UniqueProcessKind {
        self = initialState
    }
}

extension ProcessState {

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

    public func isRunning(_ process: ProcessKind) -> Bool where ProcessKind: Equatable {
        if case .running(let runningProcess) = self { return runningProcess == process }
        return false
    }

    public var hasFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    public func hasFailed(_ process: ProcessKind) -> Bool where ProcessKind: Equatable {
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

    public func hasFinished(_ process: ProcessKind) -> Bool where ProcessKind: Equatable {
        if case .finished(let finishedProcess) = self { return finishedProcess == process }
        return false
    }
}

extension ProcessState: Equatable where ProcessKind: Equatable {
    nonisolated public static func == (lhs: ProcessState, rhs: ProcessState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.running(let leftId), .running(let rightId)): return leftId == rightId
        case (.failed(let leftId, _), .failed(let rightId, _)): return leftId == rightId
        case (.finished(let leftId), .finished(let rightId)): return leftId == rightId
        default: return false
        }
    }
}
