// Copyright 2023 apploft GmbH. All rights reserved.

import SwiftUI

public struct ProcessCancelError: Error, Sendable, Hashable, LocalizedError {
    public var errorDescription: String? {
        "The process was marked to be cancelled"
    }
}
public struct UniqueProcess: Equatable, Sendable {}
public struct Process<ProcessType>: Equatable, DynamicProperty where ProcessType: Equatable, ProcessType: Sendable {

    public enum ProcessState: Equatable {
        case idle
        case running(ProcessType)
        case failed(process: ProcessType, error: Swift.Error)
        case finished(ProcessType)

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

    @State public private(set) var state: ProcessState
    @State private var task: Task<Void, Never>?

    public init(initialState: ProcessState = .idle) {
        self._state = .init(initialValue: initialState)
    }

    public static func unique(initialState: ProcessState = .idle) -> Process<UniqueProcess> where ProcessType == UniqueProcess {
        .init(initialState: initialState)
    }

    public static func shared(by type: ProcessType.Type, initialState: ProcessState = .idle) -> Process<ProcessType> {
        Process<ProcessType>(initialState: initialState)
    }

    // MARK: - Manual Process Modifiers

    public func cancel(resetToIdle: Bool = true) {
        if resetToIdle { state = .idle }
        task?.cancel()
        task = nil
    }

    public func start(_ process: ProcessType) {
        cancel(resetToIdle: false)
        state = .running(process)
    }

    public func start() where ProcessType == UniqueProcess {
        start(.init())
    }

    public func fail(with error: Swift.Error) {
        cancel(resetToIdle: false)
        guard case .running(let process) = state else {
            return
        }

        state = .failed(process: process, error: error)
    }

    public func finish() {
        guard case .running(let process) = state else {
            return
        }

        state = .finished(process)
    }

    public func setFailed(_ process: ProcessType, error: Swift.Error) {
        cancel(resetToIdle: false)
        state = .failed(process: process, error: error)
    }

    public func setFinished(_ process: ProcessType) {
        state = .finished(process)
    }

    public func setFinished() where ProcessType == UniqueProcess {
        state = .finished(.init())
    }

    // MARK: - Automatic Process Modifiers

    @MainActor @discardableResult public func run(
        _ process: ProcessType,
        resetToIdle: Bool = false,
        block: @MainActor @escaping () async throws -> Void
    ) -> Task<Void, Never> {
        if resetToIdle { state = .idle }
        cancel()
        let task = Task {
            do {
                state = .running(process)
                try await block()
                state = .finished(process)
            } catch is CancellationError {
                // Task was cancelled. Don't change the state anymore
            } catch is ProcessCancelError {
                cancel()
            } catch {
                state = .failed(process: process, error: error)
            }
        }
        self.task = task
        return task
    }

    @MainActor public func runAndWait(
        _ process: ProcessType,
        resetToIdle: Bool = false,
        block: @MainActor @escaping () async throws -> Void
    ) async {
        await run(process, resetToIdle: resetToIdle, block: block).value
    }

    @MainActor public func run(
        resetToIdle: Bool = false,
        block: @escaping () async throws -> Void
    ) where ProcessType == UniqueProcess {
        run(.init(), resetToIdle: resetToIdle, block: block)
    }

    @MainActor public func runAndWait(
        resetToIdle: Bool = false,
        block: @MainActor @escaping () async throws -> Void
    ) async where ProcessType == UniqueProcess {
        await run(.init(), resetToIdle: resetToIdle, block: block).value
    }

    // MARK: - Convenience Methods

    /// Returns an equatable object based on the current process state, while ignoring non-equatable errors.
    ///
    /// Note that different non-equatable error will not be differentiated with this. To do this, use an equatable error type to make the entire `Process` type equatable.
    @available(*, deprecated, message: "The type itself is now Equatable")
    public var equatableState: some Equatable {
        true
    }

    public var isIdle: Bool {
        if case .idle = state { return true }
        return false
    }

    public var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    public func isRunning(_ process: ProcessType) -> Bool {
        if case .running(let runningProcess) = state { return runningProcess == process }
        return false
    }

    public var hasFailed: Bool {
        if case .failed = state { return true }
        return false
    }

    public var error: Error? {
        if case .failed(_, let error) = state { return error }
        return nil
    }

    public var hasFinished: Bool {
        if case .finished = state { return true }
        return false
    }

    public static func == (lhs: Process<ProcessType>, rhs: Process<ProcessType>) -> Bool {
        lhs.state == rhs.state
    }
}
