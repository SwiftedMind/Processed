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

@MainActor
public protocol ProcessSupport where Self: ObservableObject {
    func cancelProcess<ProcessID>(
        _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>
    )

    func run<ProcessID>(
        _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
        as processKind: ProcessID,
        silently runSilently: Bool,
        priority: TaskPriority?,
        block: @escaping () async throws -> Void
    )

    func run<ProcessID>(
        _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
        as process: ProcessID,
        silently runSilently: Bool,
        priority: TaskPriority?,
        block: @escaping () async throws -> Void
    ) async

    func run(
        _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
        as processKind: SingleProcess,
        silently runSilently: Bool,
        priority: TaskPriority?,
        block: @escaping () async throws -> Void
    )

    func run(
        _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
        as processKind: SingleProcess,
        silently runSilently: Bool,
        priority: TaskPriority?,
        block: @escaping () async throws -> Void
    ) async
}

extension ProcessSupport {

    @MainActor public func cancelProcess<ProcessID>(_ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>) {
        let identifier = ProcessIdentifier(
            identifier: ObjectIdentifier(self),
            keyPath: processState
        )
        tasks[identifier]?.cancel()
        tasks.removeValue(forKey: identifier)
    }

    @MainActor public func run<ProcessID>(
        _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
        as processKind: ProcessID,
        silently runSilently: Bool = false,
        priority: TaskPriority? = nil,
        block: @escaping () async throws -> Void
    ) {
        let identifier = ProcessIdentifier(
            identifier: ObjectIdentifier(self),
            keyPath: processState
        )
        tasks[identifier]?.cancel()
        tasks[identifier] = Task(priority: priority) {
            defer { // Cleanup
                tasks[identifier] = nil
            }
            await run(
                processState,
                as: processKind,
                silently: runSilently,
                priority: priority,
                block: block
            )
        }
    }

    @MainActor public func run<ProcessID>(
        _ processState: ReferenceWritableKeyPath<Self, ProcessState<ProcessID>>,
        as process: ProcessID,
        silently runSilently: Bool = false,
        priority: TaskPriority? = nil,
        block: @escaping () async throws -> Void
    ) async {
        do {
            if !runSilently {
                self[keyPath: processState] = .running(process)
            }
            try await block()
            self[keyPath: processState] = .finished(process)
        } catch is CancellationError {
            // Task was cancelled. Don't change the state anymore
        } catch is ProcessReset {
            self[keyPath: processState] = .idle
        } catch {
            self[keyPath: processState] = .failed(process: process, error: error)
        }
    }

    @MainActor public func run(
        _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
        as process: SingleProcess = .init(),
        silently runSilently: Bool = false,
        priority: TaskPriority? = nil,
        block: @escaping () async throws -> Void
    ) {
        let identifier = ProcessIdentifier(
            identifier: ObjectIdentifier(self),
            keyPath: processState
        )
        tasks[identifier]?.cancel()
        tasks[identifier] = Task(priority: priority) {
            defer { // Cleanup
                tasks[identifier] = nil
            }
            await run(
                processState,
                as: process,
                silently: runSilently,
                priority: priority,
                block: block
            )
        }
    }

    @MainActor public func run(
        _ processState: ReferenceWritableKeyPath<Self, ProcessState<SingleProcess>>,
        as process: SingleProcess = .init(),
        silently runSilently: Bool = false,
        priority: TaskPriority? = nil,
        block: @escaping () async throws -> Void
    ) async {
        do {
            if !runSilently {
                self[keyPath: processState] = .running(process)
            }
            try await block()
            self[keyPath: processState] = .finished(process)
        } catch is CancellationError {
            // Task was cancelled. Don't change the state anymore
        } catch is ProcessReset {
            self[keyPath: processState] = .idle
        } catch {
            self[keyPath: processState] = .failed(process: process, error: error)
        }
    }
}
