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

struct RefreshableLoadableInClassDemo: View {
  @MainActor final class ViewModel: ObservableObject, LoadableSupport {

    @Published var numbers: LoadableState<[Int]> = .absent

    @MainActor func loadNumbers() {
      load(\.numbers) { [weak self] in
        guard let self else { throw CancelProcess() }
        return try await fetchNumbers()
      }
    }

    @MainActor func refreshNumbers() async {
      await load(\.numbers, silently: true) { [weak self] in
        guard let self else { throw CancelProcess() }
        let numbers = try await fetchNumbers()
        return numbers.shuffled() // Shuffle them to show that they changed
      }
    }

    // Demo extraction of the loading logic. This would typically be somewhere else
    @MainActor func fetchNumbers() async throws -> [Int] {
        try await Task.sleep(for: .seconds(2))
        return [1, 2, 3, 4, 5]
    }
  }

  @StateObject var viewModel = ViewModel()

  var body: some View {
    List {
      loadableState
    }
    .animation(.default, value: viewModel.numbers)
    .navigationTitle("Refreshable Loadable")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      // On view appear, we load the numbers while showing a loading indicator
      viewModel.loadNumbers()
    }
    .refreshable {
      // On a refresh, we skip the loading indicator so the current ".loaded" or ".error" state is kept until
      // we override it with a new ".loaded" or ".error" state
      await viewModel.refreshNumbers()
    }
  }

  @ViewBuilder @MainActor
  private var loadableState: some View {
    switch viewModel.numbers {
    case .absent:
      EmptyView()
    case .loading:
      ProgressView()
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    case .error:
      Text("An error occurred")
    case .loaded(let numbers):
      Section {
        Text("Pull down to refresh the numbers")
      }
      Section {
        ForEach(numbers, id: \.self) { number in
          Text(String(number))
        }
      }
    }
  }
}

#Preview {
  MainActor.assumeIsolated {
    NavigationStack {
      RefreshableLoadableInClassDemo().preferredColorScheme(.dark)
    }
  }
}
