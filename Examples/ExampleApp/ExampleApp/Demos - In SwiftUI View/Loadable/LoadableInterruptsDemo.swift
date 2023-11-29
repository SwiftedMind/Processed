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

struct LoadableInterruptsDemo: View {
  
  @Loadable<[Int]> var numbers
  @State var showLoadingDelay: Bool = false
  
  var body: some View {
    List {
      buttons
      loadableState
    }
    .animation(.default, value: numbers)
    .animation(.default, value: showLoadingDelay)
    .navigationTitle("Loadable Interrupts")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: numbers) {
      showLoadingDelay = false
    }
    .onDisappear {
      $numbers.cancel()
    }
  }
  
  @ViewBuilder @MainActor
  private var buttons: some View {
    Section {
      Button("Load all numbers") {
        load()
      }
      Button("Load with timeout") {
        loadWithTimeout()
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
      VStack {
        ProgressView().id(UUID())
          .padding(.vertical)
        if showLoadingDelay {
          Text("The process seems to run longer than expected")
            .lineLimit(2, reservesSpace: true)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity)
      .listRowBackground(Color.clear)
    case .error(let error):
      switch error {
      case is TimeoutError:
        Text("Timeout")
          .foregroundStyle(.red)
      default:
        Text("An error occurred: \(error.localizedDescription)")
          .foregroundStyle(.red)
      }
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
  
  @MainActor func loadWithTimeout() {
    // Show "delay" info after 1 second, and time out after 2 seconds
    $numbers.load(interrupts: [.seconds(2), .seconds(3)]) {
      try await Task.sleep(for: .seconds(10))
      return [1, 2, 3, 4, 5]
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
  MainActor.assumeIsolated {
    NavigationStack {
      LoadableInterruptsDemo().preferredColorScheme(.dark)
    }
  }
}
