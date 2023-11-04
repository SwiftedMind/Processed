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
import Processed

struct ProcessInterruptsDemo: View {

  @Process var process
  @State var showLoadingDelay = false

  var body: some View {
    List {
      buttons
      processState
    }
    .animation(.default, value: process)
    .animation(.default, value: showLoadingDelay)
    .navigationTitle("Process Interrupts")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: process) {
      showLoadingDelay = false
    }
    .onDisappear {
      $process.cancel()
    }
  }

  @ViewBuilder @MainActor
  private var buttons: some View {
    Section {
      Button("Run process with success") {
        runSuccess()
      }
      .disabled(process.isRunning)
      Button("Run process with timeout") {
        runTimeout()
      }
      .disabled(process.isRunning)
    }

    Section {
      Button("Cancel") {
        // Cancel the current process and keep the state where it currently is
        // so that you can start a new process without introducing data races
        $process.cancel()
      }
      Button("Reset") {
        // Cancel the current process and reset the state to .idle
        $process.reset()
      }
    }
  }

  @ViewBuilder @MainActor
  private var processState: some View {
    Section {
      switch process {
      case .idle:
        Text("Idle")
      case .running:
        HStack {
          Text("Running")
          Spacer()
          ProgressView().id(UUID())
        }
      case .failed(_, let error):
        switch error {
        case is TimeoutError:
          Text("Timeout")
            .foregroundStyle(.red)
        default:
          Text("An error occurred: \(error.localizedDescription)")
            .foregroundStyle(.red)
        }
      case .finished:
        Text("Success!")
      }
    } header: {
      Text("Process state")
    } footer: {
      if showLoadingDelay {
        Text("The process seems to run longer than expected")
      }
    }
  }

  @MainActor func runSuccess() {
    $process.run {
      try await Task.sleep(for: .seconds(2))
    }
  }

  @MainActor func runTimeout() {
    // Show "delay" info after 1 second, and time out after 2 seconds
    $process.run(interrupts: [.seconds(2), .seconds(3)]) {
      try await Task.sleep(for: .seconds(10))
    } onInterrupt: { accumulatedDelay in
      switch accumulatedDelay {
      case .seconds(5): // Accumulated 3 seconds at this point
        throw TimeoutError()
      default: 
        showLoadingDelay = true
      }
    }
  }
}

#Preview {
  NavigationStack {
    ProcessInterruptsDemo().preferredColorScheme(.dark)
  }
}
