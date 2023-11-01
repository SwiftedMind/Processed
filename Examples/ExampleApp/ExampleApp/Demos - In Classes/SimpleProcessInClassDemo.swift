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

struct SimpleProcessInClassDemo: View {

  @MainActor final class ViewModel: ObservableObject, ProcessSupport {
    @Published var process: ProcessState<SingleProcess> = .idle

    func cancelProcess() {
      cancel(\.process)
    }

    func resetProcess() {
      reset(\.process)
    }

    func runSuccess() {
      run(\.process) {
        try await Task.sleep(for: .seconds(2))
      }
    }

    func runError() {
      run(\.process) {
        try await Task.sleep(for: .seconds(2))
        throw NSError(domain: "Something went wrong", code: 500)
      }
    }
  }

  @StateObject var viewModel = ViewModel()

  var body: some View {
    List {
      buttons
      processState
    }
    .animation(.default, value: viewModel.process)
    .navigationTitle("Simple Process (Protocol)")
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder @MainActor
  private var buttons: some View {
    Section {
      Button("Run process with success") {
        viewModel.runSuccess()
      }
      .disabled(viewModel.process.isRunning)
      Button("Run process with error") {
        viewModel.runError()
      }
      .disabled(viewModel.process.isRunning)
    }

    Section {
      Button("Cancel") {
        // Cancel the current process and keep the state where it currently is
        // so that you can start a new process without introducing data races
        viewModel.cancelProcess()
      }
      Button("Reset") {
        // Cancel the current process and reset the state to .idle
        viewModel.resetProcess()
      }
    }
  }

  @ViewBuilder @MainActor
  private var processState: some View {
    Section {
      switch viewModel.process {
      case .idle:
        Text("Idle")
      case .running:
        HStack {
          Text("Running")
          Spacer()
          ProgressView().id(UUID())
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
}

#Preview {
  NavigationStack {
    SimpleProcessInClassDemo().preferredColorScheme(.dark)
  }
}
