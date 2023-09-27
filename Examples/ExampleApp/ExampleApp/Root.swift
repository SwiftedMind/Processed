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

struct Root: View {

  enum Destination: Hashable {
    case singleProcess
    case sharedProcess
    case loadable
    case restartable
    case singleProcessInClass
    case sharedProcessInClass
    case loadableInClass
  }

  @State var path: [Destination] = []

  var body: some View {
    NavigationStack(path: $path) {
      List {
        header
        Section {
          NavigationLink(value: Destination.singleProcess) {
            Text("Single process")
          }
          NavigationLink(value: Destination.sharedProcess) {
            Text("Shared process")
          }
          NavigationLink(value: Destination.loadable) {
            Text("Loadable")
          }
          NavigationLink(value: Destination.loadable) {
            Text("Restartable Loadable")
          }
        } header: {
          Text("SwiftUI Views")
        } footer: {
          Text("See how you can use the `@Loadable` and `@Process` property wrappers directly in your views.")
        }
        Section {
          NavigationLink(value: Destination.singleProcessInClass) {
            Text("Single process in class")
          }
          NavigationLink(value: Destination.sharedProcessInClass) {
            Text("Shared process in class")
          }
          NavigationLink(value: Destination.loadableInClass) {
            Text("Loadable in class")
          }
        } header: {
          Text("Class Demos")
        } footer: {
          Text("See how you can use `LoadableSupport` and `ProcessSupport` in an `ObservableObject` or any other class.")
        }
      }
      .navigationTitle("Demos")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(for: Destination.self) { destination in
        switch destination {
        case .singleProcess:
          SingleProcessDemo()
        case .sharedProcess:
          SharedProcessDemo()
        case .loadable:
          LoadableDemo()
        case .restartable:
          RestartableDemo()
        case .singleProcessInClass:
          SingleProcessInClassDemo()
        case .sharedProcessInClass:
          SharedProcessInClassDemo()
        case .loadableInClass:
          LoadableInClassDemo()
        }
      }
    }
  }

  @ViewBuilder @MainActor
  private var header: some View {
    Section {
      VStack {
        Image(.logo)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: 80)
        Text("Processed")
          .font(.system(size: 40, weight: .semibold))
          .frame(maxWidth: .infinity)
        Text("Demo")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical)
    }
  }
}

#Preview {
  Root().preferredColorScheme(.dark)
}
