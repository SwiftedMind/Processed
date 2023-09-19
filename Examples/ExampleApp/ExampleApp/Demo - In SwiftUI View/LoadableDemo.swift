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

struct LoadableDemo: View {

  @Loadable var numbers: LoadableState<[Int]>

  var body: some View {
    List {
      buttons
      loadableState
    }
    .animation(.default, value: numbers)
    .navigationTitle("Loadable Demo")
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder @MainActor
  private var buttons: some View {
    Section {
      Button("Load All Numbers") {
        load()
      }
      Button("Stream Numbers") {
        stream()
      }
    }

    Section {
      Button("Cancel") {
        // Cancel the current loading process and keep the state where it currently is
        // so that you can start a new process without introducing data races
        $numbers.cancel()
      }
      Button("Reset") {
        // Cancel the current loading process and reset the state to .absent
        $numbers.reset()
      }
    }
  }

  @ViewBuilder @MainActor
  private var loadableState: some View {
    switch numbers {
    case .absent:
      EmptyView()
    case .loading:
      ProgressView()
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

  @MainActor func load() {
    $numbers.load {
      try await Task.sleep(for: .seconds(2))
      return [1, 2, 3, 4, 5]
    }
  }

  @MainActor func stream() {
    $numbers.load { yield in
      var numbers: [Int] = []
      for await number in [1, 2, 3, 4, 5].publisher.values {
        try await Task.sleep(for: .seconds(1))
        numbers.append(number)
        yield(.loaded(numbers))
      }
    }
  }
}

#Preview {
  MainActor.assumeIsolated {
    NavigationStack {
      LoadableDemo().preferredColorScheme(.dark)
    }
  }
}
