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

import XCTest
@testable import Processed
import SwiftUI

private struct EquatableError: Error, Equatable {}

final class LoadableInClassTests: XCTestCase {
  @MainActor func testBasic() async throws {
    let container = LoadableContainer<Int>()

    await container.load(\.loadable) {
      return 42
    }

    XCTAssertEqual(container.loadableHistory, [.absent, .loading, .loaded(42)])
  }

  @MainActor func testBasicYielding() async throws {
    let container = LoadableContainer<Int>()

    await container.load(\.loadable) { yield in
      yield(.loaded(42))
      yield(.loaded(73))
    }

    XCTAssertEqual(container.loadableHistory, [.absent, .loading, .loaded(42), .loaded(73)])
  }

  @MainActor func testReset() async throws {
    let container = LoadableContainer<Int>()

    await container.load(\.loadable) {
      return 42
    }

    container.reset(\.loadable)

    XCTAssertEqual(container.loadableHistory, [.absent, .loading, .loaded(42), .absent])
  }

  @MainActor func testCancel() async throws {
    let container = LoadableContainer<Int>()

    let task = Task {
      await container.load(\.loadable) {
        try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
        XCTFail("Should not get here!")
        throw EquatableError()
      }
    }

    task.cancel()
    await task.value

    XCTAssertEqual(container.loadableHistory, [.absent, .loading])
  }

  @MainActor func testResetError() async throws {
    let container = LoadableContainer<Int>()

    await container.load(\.loadable) {
      throw CancelLoadable()
    }

    XCTAssertEqual(container.loadableHistory, [.absent, .loading, .absent])
  }

  @MainActor func testErrorStates() async throws {
    let container = LoadableContainer<Int>()

    await container.load(\.loadable) {
      throw EquatableError()
    }

    XCTAssertEqual(container.loadableHistory, [.absent, .loading, .error(EquatableError())])
  }

  @MainActor func testRunSilently() async throws {
    let container = LoadableContainer<Int>()

    await container.load(\.loadable, silently: true) {
      return 42
    }

    XCTAssertEqual(container.loadableHistory, [.absent, .loaded(42)])
  }

  @MainActor func testRunTwice() async throws {
    let container = LoadableContainer<Int>()

    await container.load(\.loadable) {
      return 42
    }

    await container.load(\.loadable) {
      return 73
    }

    XCTAssertEqual(container.loadableHistory, [
      .absent,
      .loading,
      .loaded(42),
      .loading,
      .loaded(73)
    ])
  }

  @MainActor func testRunTwiceFailFirst() async throws {
    let container = LoadableContainer<Int>()

    await container.load(\.loadable) {
      throw EquatableError()
    }

    await container.load(\.loadable) {
      return 42
    }

    XCTAssertEqual(container.loadableHistory, [
      .absent,
      .loading,
      .error(EquatableError()),
      .loading,
      .loaded(42)
    ])
  }
}


