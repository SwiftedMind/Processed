// Copyright 2023 apploft GmbH. All rights reserved.

import SwiftUI

public struct LoadableCancelError: Error, Sendable, Hashable, LocalizedError {
    public var errorDescription: String? {
        "The loadable was marked to be cancelled"
    }
}

public struct Loadable<LoadableType> {

    public enum State {
        case absent
        case loading
        case error(Error)
        case loaded(LoadableType)
    }

    public fileprivate(set) var state: State

    public init(initialState: State = .absent) {
        self.state = initialState
    }

    // MARK: - Manual Process Modifiers

    public mutating func reset() {
        state = .absent
    }

    public mutating func setLoading() {
        state = .loading
    }

    public mutating func set(_ error: Swift.Error) {
        state = .error(error)
    }

    public mutating func set(_ data: LoadableType) {
        state = .loaded(data)
    }

    // MARK: - Convenience Methods

    public var isAbsent: Bool {
        if case .absent = state { return true }
        return false
    }

    public var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    public var isError: Bool {
        if case .error = state { return true }
        return false
    }

    public var error: Swift.Error? {
        if case .error(let error) = state { return error }
        return nil
    }

    public var data: LoadableType? {
        if case .loaded(let data) = state { return data }
        return nil
    }
}

public struct LoadableProcess<LoadableType>: DynamicProperty {

    public enum LoadableState {
        case absent
        case loading
        case error(Error)
        case loaded(LoadableType)
    }

    @State private var loadable: Loadable<LoadableType>
    @State private var task: Task<Void, Never>?

    public var state: Loadable<LoadableType>.State {
        loadable.state
    }

    public init(initialState: Loadable<LoadableType>.State = .absent) {
        self._loadable = .init(initialValue: .init(initialState: initialState))
    }

    // MARK: - Manual Process Modifiers

    public func cancel(resetToAbsent: Bool = true) {
        if resetToAbsent { loadable.state = .absent }
        task?.cancel()
        task = nil
    }

    public func setLoading() {
        cancel(resetToAbsent: false)
        loadable.state = .loading
    }

    public func set(_ error: Swift.Error) {
        cancel(resetToAbsent: false)
        loadable.state = .error(error)
    }

    public func set(_ data: LoadableType) {
        cancel(resetToAbsent: false)
        loadable.state = .loaded(data)
    }

    // MARK: - Automatic Process Modifiers

    @MainActor public func run(
        resetToAbsent: Bool = false,
        block: @MainActor @escaping () async throws -> LoadableType
    ) {
        if resetToAbsent { loadable.state = .absent }
        cancel()
        task = Task {
            do {
                loadable.state = .loading
                loadable.state = try await .loaded(block())
            } catch is ProcessCancelError {
                cancel()
            } catch {
                loadable.state = .error(error)
            }
        }
    }

    @MainActor public func runContinuously(
        resetToAbsent: Bool = false,
        block: @MainActor @escaping (_ yield: (_ result: LoadableType) -> Void) async throws -> LoadableType
    ) {
        if resetToAbsent { loadable.state = .absent }
        cancel()
        task = Task {
            do {
                let yield = { result in
                    loadable.state = .loaded(result)
                }
                loadable.state = .loading
                loadable.state = try await .loaded(block(yield))
            } catch is CancellationError {
                // Task was cancelled. Don't change the state anymore
            } catch is ProcessCancelError {
                cancel()
            } catch {
                loadable.state = .error(error)
            }
        }
    }

    // MARK: - Convenience Methods

    public var isAbsent: Bool {
        if case .absent = loadable.state { return true }
        return false
    }

    public var isLoading: Bool {
        if case .loading = loadable.state { return true }
        return false
    }

    public var isError: Bool {
        if case .error = loadable.state { return true }
        return false
    }

    public var error: Swift.Error? {
        if case .error(let error) = loadable.state { return error }
        return nil
    }

    public var data: LoadableType? {
        if case .loaded(let data) = loadable.state { return data }
        return nil
    }
}

extension Loadable.State: Equatable where LoadableType: Equatable {
    nonisolated public static func == (
        lhs: Loadable<LoadableType>.State,
        rhs: Loadable<LoadableType>.State
    ) -> Bool {
        switch (lhs, rhs) {
        case (.absent, .absent): return true
        case (.loading, .loading): return true
        case (.error, .error): return true
        case (.loaded(let leftData), .loaded(let rightData)): return leftData == rightData
        default: return false
        }
    }
}

extension Loadable: Equatable where LoadableType: Equatable {
    public static func == (lhs: Loadable<LoadableType>, rhs: Loadable<LoadableType>) -> Bool {
        lhs.state == rhs.state
    }
}

extension LoadableProcess: Equatable where LoadableType: Equatable {
    public static func == (lhs: LoadableProcess<LoadableType>, rhs: LoadableProcess<LoadableType>) -> Bool {
        lhs.loadable.state == rhs.loadable.state
    }
}
