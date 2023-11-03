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

struct RestartableLoadableInClassDemo: View {
  @MainActor final class ViewModel: ObservableObject, LoadableSupport {
    
    @Published var numbersObservationId: UUID = .init()
    @Published var shouldFail: Bool = false
    @Published var numbers: LoadableState<[Int]> = .absent
    
    func stream() async {
      await load(\.numbers) { yield in
        var numbers: [Int] = []
        for await number in (1...100).publisher.values {
          try await Task.sleep(for: .seconds(1))

          if shouldFail {
            shouldFail = false // Reset
            throw NSError(domain: "", code: 42)
          }

          numbers.append(number)
          yield(.loaded(numbers))
        }
      }
    }
    
    func restartStream() {
      numbersObservationId = .init()
    }
  }
  
  @StateObject var viewModel = ViewModel()
  
  var body: some View {
    List {
      buttons
      loadableState
    }
    .animation(.default, value: viewModel.numbers)
    .navigationTitle("Restartable Loadable (Protocol)")
    .navigationBarTitleDisplayMode(.inline)
    .task(id: viewModel.numbersObservationId) {
      // This task will cancel when the view disappears and restart if numbersObservationId changes
      await viewModel.stream()
    }
  }
  
  @ViewBuilder @MainActor
  private var buttons: some View {
    Section {
      Button("Simulate stream error", role: .cancel) {
        viewModel.shouldFail = true
      }
      .disabled(viewModel.numbers.isError)
    } footer: {
      Text("Tap here to interrupt the loading stream and simulate an error case so you can test a restart")
    }
  }

  @ViewBuilder @MainActor
  private var loadableState: some View {
    switch viewModel.numbers {
    case .absent:
      EmptyView()
    case .loading:
      ProgressView().id(UUID())
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    case .error:
      VStack {
        Text("An error occurred")
        Button("Retry") {
          viewModel.restartStream()
        }
        .buttonStyle(.borderedProminent)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical)
    case .loaded(let numbers):
      ForEach(numbers, id: \.self) { number in
        Text(String(number))
      }
    }
  }
}

#Preview {
  MainActor.assumeIsolated {
    NavigationStack {
      RestartableLoadableInClassDemo().preferredColorScheme(.dark)
    }
  }
}
