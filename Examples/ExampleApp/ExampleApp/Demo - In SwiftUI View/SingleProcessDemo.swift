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

struct SingleProcessDemo: View {

  @Process var process

  var body: some View {
    List {
      buttons
      processState
    }
    .animation(.default, value: process)
    .navigationTitle("Single Process Demo")
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder @MainActor
  private var buttons: some View {
    Section {
      Button("Run process with success") {
        runSuccess()
      }
      .disabled(process.isRunning)
      Button("Run process with error") {
        runError()
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
          ProgressView()
        }
      case .failed(_, let error):
        Text("An error occurred: \(error.localizedDescription)")
          .foregroundStyle(.red)
      case .finished:
        Text("Success!")
      }
    } header: {
      Text("Process state")
    }
  }

  @MainActor func runSuccess() {
    $process.run {
      try await Task.sleep(for: .seconds(2))
    }
  }

  @MainActor func runError() {
    $process.run {
      try await Task.sleep(for: .seconds(2))
      throw NSError(domain: "Something went wrong", code: 500)
    }
  }
}

#Preview {
  NavigationStack {
    SingleProcessDemo().preferredColorScheme(.dark)
  }
}
