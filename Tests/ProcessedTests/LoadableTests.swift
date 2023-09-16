import XCTest
@testable import Processed

@MainActor final class LoadableTests: XCTestCase {

    @MainActor func testBasic() async throws {
    }

//    @MainActor func testBasic() async throws {
//        let loadable = Loadable<Int>()
//        XCTAssertEqual(loadable.state, .absent)
//
//        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
//
//        let task = Task {
//            var states: [Loadable<Int>.LoadableState] = []
//            for await state in loadable.$state.values {
//                states.append(state)
//                continuation.yield()
//            }
//            print(states.debugDescription)
//        }
//
//        continuation.onTermination = { _ in
//            task.cancel()
//        }
//
//        // This makes sure that the for-await observation Task above is
//        // set up and ready. Otherwise, `loadable.run` could run BEFORE the for-await loop is executed
//        for await _ in stream { break }
//
//        // This starts sometimes BEFORE the for await is reached above, since it is in parallel
//        loadable.load {
//            return 5
//        }
//
//        await loadable.task?.value
//
//        // TODO: Is it guaranteed, that the canceled task receives all outstanding states from loadable.run?
//        continuation.finish()
//    }
//    
//    /// Test the custom `LoadableCancellationError` that cancels the process and resets its state back to .absent
//    @MainActor func testBasicCancellation() async throws {
//        let loadable = Loadable<Int>()
//        XCTAssertEqual(loadable.state, .absent)
//
//        let (stream, continuation) = AsyncStream.makeStream(of: Loadable<Int>.LoadableState.self)
//
//        let task = Task {
//            for await state in loadable.$state.values {
//                print(state)
//                continuation.finish()
//            }
//        }
//
//        // This makes sure that the for-await observation Task above is
//        // set up and ready. Otherwise, `loadable.run` could run BEFORE the for-await loop is executed
//        for await _ in stream {}
//
//        // This starts sometimes BEFORE the for await is reached above, since it is in parallel
//        loadable.load {
//            throw LoadableCancellationError()
//        }
//
//        await task.value
//
//        await task.value
//    }
//
//    func testYielding() async throws {
//        let loadable = Loadable<Int>()
//
//        Task {
//            var expectedStates: [Loadable<Int>.LoadableState] = [.absent, .loading, .loaded(1), .loaded(2), .loaded(3)]
//            for await state in loadable.$state.values {
//                if expectedStates.isEmpty { break }
//                let expectedState = expectedStates.removeFirst()
//                XCTAssertEqual(state, expectedState)
//            }
//        }
//
//        loadable.load { yield in
//            yield(1)
//            yield(2)
//            return 3
//        }
//    }
//
//    func testYieldingCancellation() async throws {
//        let loadable = Loadable<Int>()
//
//        Task {
//            var expectedStates: [Loadable<Int>.LoadableState] = [.absent, .loading, .loaded(1), .loaded(2), .loaded(3)]
//            for await state in loadable.$state.values {
//                if expectedStates.isEmpty { break }
//                let expectedState = expectedStates.removeFirst()
//                XCTAssertEqual(state, expectedState)
//            }
//        }
//
//        loadable.load { yield in
//            yield(1)
//            yield(2)
//            return 3
//        }
//    }

}
