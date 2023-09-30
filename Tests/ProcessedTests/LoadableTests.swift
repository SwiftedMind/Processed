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
import SwiftUI
@testable import Processed

private struct EquatableError: Error, Equatable {}

@MainActor final class LoadableTests: XCTestCase {
  
  @MainActor func testBasic() async throws {
    let container = LoadableContainer<Int>()
    let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)
    
    await binding.load {
      return 42
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
    
    XCTAssertEqual(container.loadableHistory, [.absent, .loading, .loaded(42), .loaded(73), .loading, .loaded(100)])
  }
  
  @MainActor func testRunSilently() async throws {
    let container = LoadableContainer<Int>()
    let binding = Loadable.Binding(state: container.loadableBinding, task: container.taskBinding)
    
    await binding.load(silently: true) {
      return 42
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
      return 42
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
    
    XCTAssertEqual(container.loadableHistory, [.absent, .loading,])
  }
}
