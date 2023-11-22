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

struct FailureAlertProcessInClassDemo: View {

  @MainActor final class ViewModel: ObservableObject, ProcessSupport {
    @Published var process: ProcessState<SingleProcess> = .idle
    @Published var showAlert: Bool = false
    
    private var observationTask: Task<Void, Never>?
    
    init() {
      observationTask = Task {
        await observeProcess()
      }
    }
    
    func onDisappear() {
      observationTask?.cancel()
      cancel(\.process)
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
    
    // MARK: - Internal Observation
    
    private func observeProcess() async {
      for await state in $process.values {
        showAlert = state.hasFailed
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
    .navigationTitle("Failure Alert Process (Protocol)")
    .navigationBarTitleDisplayMode(.inline)
    .alert("An error occurred", isPresented: $viewModel.showAlert) {
      Button("Try again") {
        viewModel.runSuccess()
      }
    } message: {
      Text("Something went horribly, horribly wrong")
    }
    .onDisappear {
      viewModel.onDisappear()
    }
  }

  @ViewBuilder @MainActor
  private var buttons: some View {
    Section {
      Button("Run process") {
        viewModel.runError()
      }
      .disabled(viewModel.process.isRunning)
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
      case .failed:
        EmptyView()
      case .finished:
        Text("Success!")
      }
    } header: {
      if !viewModel.process.hasFailed {
        Text("Process state")
      }
    }
  }
}

#Preview {
  NavigationStack {
    FailureAlertProcessInClassDemo().preferredColorScheme(.dark)
  }
}
