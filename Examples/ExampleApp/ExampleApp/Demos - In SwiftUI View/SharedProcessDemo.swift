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

struct SharedProcessDemo: View {

  enum ProcessKind: String, Equatable {
    case save = "Save"
    case delete = "Delete"
  }

  @Process<ProcessKind> var process

  var body: some View {
    List {
      buttons
      processState
    }
    .animation(.default, value: process)
    .navigationTitle("Shared Process")
    .navigationBarTitleDisplayMode(.inline)
    .onDisappear {
      $process.cancel()
    }
  }

  @ViewBuilder @MainActor
  private var buttons: some View {
    Section {
      Button("Save") {
        save()
      }
      .withLoadingIndicator()
      .loading(process.isRunning(.save))
      .disabled(process.isRunning)
      Button("Delete", role: .destructive) {
        delete()
      }
      .withLoadingIndicator()
      .loading(process.isRunning(.delete))
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
      case .running(let process):
        HStack {
          Text("Running \(process.rawValue)")
          Spacer()
          ProgressView().id(UUID())
        }
      case .failed(let process, let error):
        Text("An error occurred during \(process.rawValue): \(error.localizedDescription)")
          .foregroundStyle(.red)
      case .finished(let process):
        Text("Finished \(process.rawValue)")
      }
    } header: {
      Text("Process state")
    }
  }

  @MainActor func save() {
    $process.run(.save) {
      try await Task.sleep(for: .seconds(2))
    }
  }

  @MainActor func delete() {
    $process.run(.delete) {
      try await Task.sleep(for: .seconds(2))
    }
  }
}

#Preview {
  NavigationStack {
    SharedProcessDemo().preferredColorScheme(.dark)
  }
}
