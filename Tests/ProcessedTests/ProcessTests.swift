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

final class ProcessTests: XCTestCase {
  
  @MainActor func testBasicStates() async throws {
    let container = ProcessContainer<SingleProcess>()
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    
    await binding.run(process) {
      return
    }
    
    XCTAssertEqual(container.processHistory, [.idle, .running(process), .finished(process)])
  }
  
  @MainActor func testReset() async throws {
    let container = ProcessContainer<SingleProcess>()
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    
    await binding.run(process) {
      return
    }
    
    binding.reset()
    
    XCTAssertEqual(container.processHistory, [.idle, .running(process), .finished(process), .idle])
  }
  
  @MainActor func testCancel() async throws {
    let container = ProcessContainer<SingleProcess>()
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    
    let task = Task {
      await binding.run(process) {
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
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    
    await binding.run(process) {
      throw CancelProcess()
    }
    
    XCTAssertEqual(container.processHistory, [.idle, .running(process)])
  }
  
  @MainActor func testResetError() async throws {
    let container = ProcessContainer<SingleProcess>()
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    
    await binding.run(process) {
      throw ResetProcess()
    }
    
    XCTAssertEqual(container.processHistory, [.idle, .running(process), .idle])
  }
  
  @MainActor func testErrorStates() async throws {
    let container = ProcessContainer<SingleProcess>()
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    
    await binding.run(process) {
      throw EquatableError()
    }
    
    XCTAssertEqual(container.processHistory, [.idle, .running(process), .failed(process: process, error: EquatableError())])
  }
  
  @MainActor func testRunSilently() async throws {
    let container = ProcessContainer<SingleProcess>()
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    
    await binding.run(process, silently: true) {
      return
    }
    
    XCTAssertEqual(container.processHistory, [.idle, .finished(process)])
  }
  
  @MainActor func testRunTwice() async throws {
    let container = ProcessContainer<SingleProcess>()
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    let secondProcess = SingleProcess(id: "2")
    
    await binding.run(process) {
      return
    }
    
    await binding.run(secondProcess) {
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
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    let secondProcess = SingleProcess(id: "2")
    
    await binding.run(process) {
      throw EquatableError()
    }
    
    await binding.run(secondProcess) {
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
  
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @MainActor func testBasicTimeout() async throws {
    let container = ProcessContainer<SingleProcess>()
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    
    await binding.run(process, interrupts: [.milliseconds(100)]) {
      try await Task.sleep(for: .milliseconds(200))
    } onInterrupt: { accumulatedDelay in
      throw TimeoutError()
    }
    
    XCTAssertEqual(container.processHistory, [.idle, .running(process), .failed(process: process, error: TimeoutError())])
  }
  
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @MainActor func testUnneededTimeout() async throws {
    let container = ProcessContainer<SingleProcess>()
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    
    await binding.run(process, interrupts: [.milliseconds(200)]) {
      try await Task.sleep(for: .milliseconds(100))
    } onInterrupt: { accumulatedDelay in
      throw TimeoutError()
    }
    
    XCTAssertEqual(container.processHistory, [.idle, .running(process), .finished(process)])
  }
  
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @MainActor func testMultipleInterrupts() async throws {
    let container = ProcessContainer<SingleProcess>()
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    
    var count = 0
    await binding.run(process, interrupts: [.milliseconds(100), .milliseconds(300)]) {
      try await Task.sleep(for: .milliseconds(500))
    } onInterrupt: { accumulatedDelay in
      count += 1
      if accumulatedDelay == .milliseconds(400) {
        throw EquatableError()
      }
    }
    
    XCTAssertEqual(count, 2)
    XCTAssertEqual(container.processHistory, [.idle, .running(process), .failed(process: process, error: EquatableError())])
  }
  
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @MainActor func testSecondInterruptNotNeeded() async throws {
    let container = ProcessContainer<SingleProcess>()
    let binding = Process.Binding(state: container.processBinding, task: container.taskBinding)
    let process = SingleProcess(id: "1")
    
    var count = 0
    await binding.run(process, interrupts: [.milliseconds(100), .milliseconds(300)]) {
      try await Task.sleep(for: .milliseconds(200))
    } onInterrupt: { accumulatedDelay in
      count += 1
      if accumulatedDelay == .milliseconds(400) {
        throw EquatableError()
      }
    }
    
    XCTAssertEqual(count, 1)
    XCTAssertEqual(container.processHistory, [.idle, .running(process), .finished(process)])
  }
}


