// Copyright © elvah. All rights reserved.

@testable import Processed
import SwiftUI
import XCTest

private struct EquatableError: Error, Equatable {}

@MainActor
final class LoadableTests: XCTestCase {
	@MainActor func testBasic() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load {
			42
		}

		XCTAssertEqual(container.loadableHistory, [.absent, .loading, .loaded(42)])
	}

	@MainActor func testBasicYielding() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load { yield in
			yield(.loaded(42))
			yield(.loaded(73))
		}

		XCTAssertEqual(container.loadableHistory, [.absent, .loading, .loaded(42), .loaded(73)])
	}

	@MainActor func testMultipleYielding() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load { yield in
			yield(.loaded(42))
			yield(.loaded(73))
		}

		await binding.load { yield in
			yield(.loaded(100))
		}

		XCTAssertEqual(
			container.loadableHistory,
			[.absent, .loading, .loaded(42), .loaded(73), .loading, .loaded(100)]
		)
	}

	@MainActor func testRunSilently() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load(silently: true) {
			42
		}

		XCTAssertEqual(container.loadableHistory, [.absent, .loaded(42)])
	}

	@MainActor func testRunSilentlyWithYielding() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load(silently: true) { yield in
			yield(.loaded(42))
		}

		XCTAssertEqual(container.loadableHistory, [.absent, .loaded(42)])
	}

	@MainActor func testReset() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load {
			42
		}

		binding.reset()

		XCTAssertEqual(container.loadableHistory, [.absent, .loading, .loaded(42), .absent])
	}

	@MainActor func testResetThrow() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load {
			throw CancelLoadable()
		}

		XCTAssertEqual(container.loadableHistory, [.absent, .loading])
	}

	@MainActor func testResetThrowAndCancel() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load {
			throw CancelLoadable()
		}

		binding.cancel()

		XCTAssertEqual(container.loadableHistory, [.absent, .loading])
	}

	@MainActor func testCancel() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		let task = Task {
			await binding.load {
				try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
				XCTFail("Should not get here!")
				return 0
			}
		}

		task.cancel()
		await task.value

		XCTAssertEqual(container.loadableHistory, [.absent, .loading])
	}

	@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
	@MainActor func testBasicTimeout() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load(interrupts: [.milliseconds(100)]) {
			try await Task.sleep(for: .milliseconds(200))
			return 42
		} onInterrupt: { accumulatedDelay in
			throw TimeoutError()
		}

		XCTAssertEqual(container.loadableHistory, [.absent, .loading, .error(TimeoutError())])
	}

	@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
	@MainActor func testBasicYieldingTimeout() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load(interrupts: [.milliseconds(100)]) { yield in
			try await Task.sleep(for: .milliseconds(200))
			yield(.loaded(42))
		} onInterrupt: { accumulatedDelay in
			throw TimeoutError()
		}

		XCTAssertEqual(container.loadableHistory, [.absent, .loading, .error(TimeoutError())])
	}

	@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
	@MainActor func testUnneededTimeout() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load(interrupts: [.milliseconds(200)]) {
			try await Task.sleep(for: .milliseconds(100))
			return 42
		} onInterrupt: { accumulatedDelay in
			throw TimeoutError()
		}

		XCTAssertEqual(container.loadableHistory, [.absent, .loading, .loaded(42)])
	}

	@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
	@MainActor func testUnneededYieldingTimeout() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		await binding.load(interrupts: [.milliseconds(200)]) { yield in
			try await Task.sleep(for: .milliseconds(100))
			yield(.loaded(42))
		} onInterrupt: { accumulatedDelay in
			throw TimeoutError()
		}

		XCTAssertEqual(container.loadableHistory, [.absent, .loading, .loaded(42)])
	}

	@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
	@MainActor func testMultipleInterrupts() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		var count = 0
		await binding.load(interrupts: [.milliseconds(100), .milliseconds(300)]) {
			try await Task.sleep(for: .milliseconds(500))
			return 42
		} onInterrupt: { accumulatedDelay in
			count += 1
			if accumulatedDelay == .milliseconds(400) {
				throw EquatableError()
			}
		}

		XCTAssertEqual(count, 2)
		XCTAssertEqual(container.loadableHistory, [.absent, .loading, .error(EquatableError())])
	}

	@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
	@MainActor func testSecondInterruptNotNeeded() async throws {
		let container = LoadableContainer<Int>()
		let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)

		var count = 0
		await binding.load(interrupts: [.milliseconds(100), .milliseconds(300)]) {
			try await Task.sleep(for: .milliseconds(200))
			return 42
		} onInterrupt: { accumulatedDelay in
			count += 1
			if accumulatedDelay == .milliseconds(400) {
				throw EquatableError()
			}
		}

		XCTAssertEqual(count, 1)
		XCTAssertEqual(container.loadableHistory, [.absent, .loading, .loaded(42)])
	}
}
