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

struct SharedProcessInClassDemo: View {
  
  enum ProcessKind: String, Equatable {
    case save = "Save"
    case delete = "Delete"
  }

  @MainActor final class ViewModel: ObservableObject, ProcessSupport {

    @Published var process: ProcessState<ProcessKind> = .idle

    func cancelProcess() {
      cancel(\.process)
    }

    func resetProcess() {
      reset(\.process)
    }

    func save() {
      run(\.process, as: .save) {
        try await Task.sleep(for: .seconds(2))
      }
    }

    func delete() {
      run(\.process, as: .delete) {
        try await Task.sleep(for: .seconds(2))
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
    .navigationTitle("Shared Process (Protocol)")
    .navigationBarTitleDisplayMode(.inline)
    .onDisappear {
      viewModel.cancelProcess()
    }
  }

  @ViewBuilder @MainActor
  private var buttons: some View {
    Section {
      Button("Save") {
        viewModel.save()
      }
      .withLoadingIndicator()
      .loading(viewModel.process.isRunning(.save))
      .disabled(viewModel.process.isRunning)
      Button("Delete", role: .destructive) {
        viewModel.delete()
      }
      .withLoadingIndicator()
      .loading(viewModel.process.isRunning(.delete))
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
}

#Preview {
  NavigationStack {
    SharedProcessInClassDemo().preferredColorScheme(.dark)
  }
}
