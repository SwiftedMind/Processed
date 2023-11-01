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

final class ProcessInClassTests: XCTestCase {
  @MainActor func testBasic() async throws {
    let container = ProcessContainer<SingleProcess>()
    let process = SingleProcess(id: "1")
    
    await container.run(\.process, as: process) {
      return
    }
    
    XCTAssertEqual(container.processHistory, [.idle, .running(process), .finished(process)])
  }

  @MainActor func testReset() async throws {
    let container = ProcessContainer<SingleProcess>()
    let process = SingleProcess(id: "1")
    
    await container.run(\.process, as: process) {
      return
    }

    container.reset(\.process)

    XCTAssertEqual(container.processHistory, [.idle, .running(process), .finished(process), .idle])
  }

  @MainActor func testCancel() async throws {
    let container = ProcessContainer<SingleProcess>()
    let process = SingleProcess(id: "1")

    let task = Task {
      await container.run(\.process, as: process) {
        try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
        XCTFail("Should not get here!")
      }
    }

    task.cancel()
    await task.value

    XCTAssertEqual(container.processHistory, [.idle, .running(process)])
  }
  
  @MainActor func testCancelError() async throws {
    let container = ProcessContainer<SingleProcess>()
    let process = SingleProcess(id: "1")

    await container.run(\.process, as: process) {
      throw CancelProcess()
    }

    XCTAssertEqual(container.processHistory, [.idle, .running(process)])
  }

  @MainActor func testResetError() async throws {
    let container = ProcessContainer<SingleProcess>()
    let process = SingleProcess(id: "1")

    await container.run(\.process, as: process) {
      throw ResetProcess()
    }

    XCTAssertEqual(container.processHistory, [.idle, .running(process), .idle])
  }

  @MainActor func testErrorStates() async throws {
    let container = ProcessContainer<SingleProcess>()
    let process = SingleProcess(id: "1")

    await container.run(\.process, as: process) {
      throw EquatableError()
    }

    XCTAssertEqual(container.processHistory, [.idle, .running(process), .failed(process: process, error: EquatableError())])
  }

  @MainActor func testRunSilently() async throws {
    let container = ProcessContainer<SingleProcess>()
    let process = SingleProcess(id: "1")

    await container.run(\.process, as: process, silently: true) {
      return
    }

    XCTAssertEqual(container.processHistory, [.idle, .finished(process)])
  }

  @MainActor func testRunTwice() async throws {
    let container = ProcessContainer<SingleProcess>()
    let process = SingleProcess(id: "1")
    let secondProcess = SingleProcess(id: "2")

    await container.run(\.process, as: process) {
      return
    }

    await container.run(\.process, as: secondProcess) {
      return
    }

    XCTAssertEqual(container.processHistory, [
      .idle,
      .running(process),
      .finished(process),
      .running(secondProcess),
      .finished(secondProcess)
    ])
  }

  @MainActor func testRunTwiceFailFirst() async throws {
    let container = ProcessContainer<SingleProcess>()
    let process = SingleProcess(id: "1")
    let secondProcess = SingleProcess(id: "2")

    await container.run(\.process, as: process) {
      throw EquatableError()
    }

    await container.run(\.process, as: secondProcess) {
      return
    }

    XCTAssertEqual(container.processHistory, [
      .idle,
      .running(process),
      .failed(process: process, error: EquatableError()),
      .running(secondProcess),
      .finished(secondProcess)
    ])
  }
}


