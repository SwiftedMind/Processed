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
import Observation

@propertyWrapper public struct Loadable<LoadableType>: DynamicProperty where LoadableType: Sendable {

    public enum State {
        case absent
        case loading
        case error(Error)
        case loaded(LoadableType)
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

    public init(wrappedValue initialState: State = .absent) {
        self._state = .init(initialValue: initialState)
    }

    // MARK: - Manual Process Modifiers
    
    /// Cancels any running task associated with this process.
    private func cancel() {
        task?.cancel()
        task = nil
    }
}

extension Loadable.State {
    public mutating func setLoading() {
        self = .loading
    }

    public mutating func setError(_ error: Swift.Error) {
        self = .error(error)
    }

    public mutating func setValue(_ value: LoadableType) {
        self = .loaded(value)
    }

    // MARK: - Convenience Methods

    public var isAbsent: Bool {
        if case .absent = self { return true }
        return false
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var isError: Bool {
        if case .error = self { return true }
        return false
    }

    public var error: Swift.Error? {
        if case .error(let error) = self { return error }
        return nil
    }

    public var data: LoadableType? {
        if case .loaded(let data) = self { return data }
        return nil
    }
}

extension Loadable {
    /// A manager for controlling the process's state and execution.
    public struct Manager {
        @Binding var state: State
        @Binding var task: Task<Void, Never>?

        public func abort(reset: Bool = true) {
            if reset {
                if case .absent = state {} else {
                    state = .absent
                }
            }
            task?.cancel()
            task = nil
        }

        @MainActor @discardableResult public func load(
            silently runSilently: Bool = false,
            block: @MainActor @escaping (_ yield: (_ result: LoadableType) -> Void) async throws -> Void
        ) -> Task<Void, Never> {
            abort(reset: false)
            let task = Task {
                do {
                    if !runSilently { state = .loading }
                    try await block { result in
                        self.state = .loaded(result)
                    }
                } catch is CancellationError {
                    // Task was cancelled. Don't change the state anymore
                } catch is AbortError {
                    abort()
                } catch {
                    state = .error(error)
                }
            }
            self.task = task
            return task
        }

        @MainActor @discardableResult public func load(
            silently runSilently: Bool = false,
            block: @MainActor @escaping () async throws -> LoadableType
        ) -> Task<Void, Never> {
            abort(reset: false)
            let task = Task {
                do {
                    if !runSilently { state = .loading }
                    state = try await .loaded(block())
                } catch is CancellationError {
                    // Task was cancelled. Don't change the state anymore
                } catch is AbortError {
                    abort()
                } catch {
                    state = .error(error)
                }
            }
            self.task = task
            return task
        }

        @MainActor public func load(
            silently runSilently: Bool = false,
            block: @MainActor @escaping (_ yield: (_ result: LoadableType) -> Void) async throws -> Void
        ) async {
            await load(silently: runSilently, block: block).value
        }

        @MainActor public func load(
            silently runSilently: Bool = false,
            block: @MainActor @escaping () async throws -> LoadableType
        ) async {
            await load(silently: runSilently, block: block).value
        }
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
