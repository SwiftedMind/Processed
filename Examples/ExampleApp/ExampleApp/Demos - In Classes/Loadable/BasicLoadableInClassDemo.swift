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

struct BasicLoadableInClassDemo: View {

  @MainActor final class ViewModel: ObservableObject, LoadableSupport {

    @Published var numbers: LoadableState<[Int]> = .absent

    func cancelNumbers() {
      cancel(\.numbers)
    }

    func resetNumbers() {
      reset(\.numbers)
    }

    func load() {
      load(\.numbers) {
        try await Task.sleep(for: .seconds(2))
        return [1, 2, 3, 4, 5]
      }
    }

    func stream() {
      load(\.numbers) { yield in
        var numbers: [Int] = []
        for await number in [1, 2, 3, 4, 5].publisher.values {
          try await Task.sleep(for: .seconds(1))
          numbers.append(number)
          yield(.loaded(numbers))
        }
      }
    }
  }

  @StateObject var viewModel = ViewModel()

  var body: some View {
    List {
      buttons
      loadableState
    }
    .animation(.default, value: viewModel.numbers)
    .navigationTitle("Loadable Process (Protocol)")
    .navigationBarTitleDisplayMode(.inline)
    .onDisappear {
      viewModel.cancelNumbers()
    }
  }

  @ViewBuilder @MainActor
  private var buttons: some View {
    Section {
      Button("Load All Numbers") {
        viewModel.load()
      }
      Button("Stream Numbers") {
        viewModel.stream()
      }
    }

    Section {
      Button("Cancel") {
        // Cancel the current loading process and keep the state where it currently is
        // so that you can start a new process without introducing data races
        viewModel.cancelNumbers()
      }
      Button("Reset") {
        // Cancel the current loading process and reset the state to .absent
        viewModel.resetNumbers()
      }
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
    case .error(let error):
      Text("An error occurred: \(error.localizedDescription)")
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
      BasicLoadableInClassDemo().preferredColorScheme(.dark)
    }
  }
}
