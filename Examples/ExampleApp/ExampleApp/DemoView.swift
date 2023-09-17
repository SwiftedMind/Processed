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

struct DemoView: View {
  
  @Loadable<[Int]> var numbers
  
  var body: some View {
    List {
      Button("Load Numbers") {
        loadNumbers()
      }
      .disabled(numbers.isLoading)
      switch numbers {
      case .absent:
        EmptyView()
      case .loading:
        ProgressView()
          .frame(height: .infinity)
      case .error(let error):
        Text("An error occurred: \(error.localizedDescription)")
      case .loaded(let numbers):
        ForEach(numbers, id: \.self) { number in
          Text(String(number))
        }
      }
    }
    .animation(.default, value: numbers)
  }
  
  @MainActor func loadNumbers() {
    $numbers.load {
      try await Task.sleep(for: .seconds(2))
      return [0, 1, 2, 42, 73]
    }
  }
}



#Preview {
  DemoView()
}
