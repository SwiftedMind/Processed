// Copyright 2023 apploft GmbH. All rights reserved.

import Foundation

private enum EquatableProcessState: Equatable {
    case idle // absent
    case running // loading
    case failed // error
    case finished // loaded
}

@available(*, deprecated, message: "Please use SharedProcess")
public enum Process<Error> {
    case idle
    case running
    case failed(error: Error)
    case finished

    public init(initialState: Process<Error> = .idle) {
        self = initialState
    }

    public static func withStringError(initialState: Process<Error> = .idle) -> Process<Error> where Error == String {
        .init(initialState: initialState)
    }

    public static func withSwiftError(initialState: Process<Error> = .idle) -> Process<Error> where Error == Swift.Error {
        .init(initialState: initialState)
    }

    // MARK: - Process Modifiers

    public mutating func reset() {
        self = .idle
    }

    public mutating func start() {
        self = .running
    }

    public mutating func fail(error: Error) {
        self = .failed(error: error)
    }

    public mutating func finish() {
        self = .finished
    }

    // MARK: - Convenience Methods

    /// Returns an equatable object based on the current process state, while ignoring non-equatable errors.
    ///
    /// Note that different non-equatable error will not be differentiated with this. To do this, use an equatable error type to make the entire `Process` type equatable.
    public var equatableState: some Equatable {
        switch self {
        case .idle: return EquatableProcessState.idle
        case .running: return EquatableProcessState.running
        case .failed: return EquatableProcessState.failed
        case .finished: return EquatableProcessState.finished
        }
    }

    public var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    public var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    public var hasFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    public var error: Error? {
        if case .failed(let error) = self { return error }
        return nil
    }

    public var hasFinished: Bool {
        if case .finished = self { return true }
        return false
    }
}

extension Process: Sendable where Error: Sendable {}
extension Process: Equatable where Error: Equatable {}
extension Process: Hashable where Error: Hashable {}
