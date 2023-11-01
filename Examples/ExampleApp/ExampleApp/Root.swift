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

  enum ProcessDemoDestination: Hashable {
    case simpleProcess
    case sharedProcess
    case interrupts
    case interruptsInClass
    case simpleProcessInClass
    case sharedProcessInClass
  }
  
  enum LoadableDemoDestination: Hashable {
    case basic
    case restartable
    case refreshable
    case interrupts
    case basicInClass
    case interruptsInClass
    case restartableInClass
    case refreshableInClass
  }

  @State var path = NavigationPath()

  var body: some View {
    NavigationStack(path: $path) {
      List {
        header
        propertyWrapperDemos
        protocolDemos
      }
      .navigationTitle("Demos")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(for: ProcessDemoDestination.self) { destination in
        switch destination {
        case .simpleProcess:
          SimpleProcessDemo()
        case .sharedProcess:
          SharedProcessDemo()
        case .interrupts:
          ProcessInterruptsDemo()
        case .interruptsInClass:
          ProcessInterruptsInClassDemo()
        case .simpleProcessInClass:
          SimpleProcessInClassDemo()
        case .sharedProcessInClass:
          SharedProcessInClassDemo()
        }
      }
      .navigationDestination(for: LoadableDemoDestination.self) { destination in
        switch destination {
        case .basic:
          BasicLoadableDemo()
        case .restartable:
          RestartableLoadableDemo()
        case .refreshable:
          RefreshableLoadableDemo()
        case .interrupts:
          EmptyView()
        case .basicInClass:
          BasicLoadableInClassDemo()
        case .interruptsInClass:
          EmptyView()
        case .restartableInClass:
          RestartableLoadableInClassDemo()
        case .refreshableInClass:
          RefreshableLoadableInClassDemo()
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
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical)
    }
  }
  
  @ViewBuilder @MainActor
  private var propertyWrapperDemos: some View {
    VStack {
      Text("Property Wrapper")
        .font(.headline)
      Text("Learn how to use the `@Process` and `@Loadable` property wrappers in any SwiftUI view")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
    .listRowBackground(Color.clear)
    Section {
      NavigationLink(value: ProcessDemoDestination.simpleProcess) {
        Text("Simple Process")
      }
      NavigationLink(value: ProcessDemoDestination.sharedProcess) {
        Text("Shared Process")
      }
      NavigationLink(value: ProcessDemoDestination.interrupts) {
        Text("Process Interrupts")
      }
    } footer: {
      Text("See how you can use the `@Process` property wrapper directly in your views.")
    }

    Section {
      NavigationLink(value: LoadableDemoDestination.basic) {
        Text("Basic Loadable")
      }
      NavigationLink(value: LoadableDemoDestination.restartable) {
        Text("Restartable Loadable")
      }
      NavigationLink(value: LoadableDemoDestination.refreshable) {
        Text("Refreshable Loadable")
      }
      NavigationLink(value: LoadableDemoDestination.interrupts) {
        Text("Loadable Interrupts")
      }
    } footer: {
      Text("See how you can use the `@Loadable` property wrapper directly in your SwiftUI views.")
    }
  }
  
  @ViewBuilder @MainActor
  private var protocolDemos: some View {
    VStack {
      Text("Protocols")
        .font(.headline)
      Text("Learn how to use the `ProcessSupport` and `LoadableSupport` protocols in an `ObservableObject` or any other class")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .multilineTextAlignment(.center)
    .padding(.top)
    .frame(maxWidth: .infinity)
    .listRowBackground(Color.clear)
    Section {
      NavigationLink(value: ProcessDemoDestination.simpleProcessInClass) {
        Text("Simple Process")
      }
      NavigationLink(value: ProcessDemoDestination.sharedProcessInClass) {
        Text("Shared Process")
      }
      NavigationLink(value: ProcessDemoDestination.interruptsInClass) {
        Text("Process Interrupts")
      }
    } footer: {
      Text("See how you can use `ProcessSupport` in an `ObservableObject` or any other class.")
    }
    Section {
      NavigationLink(value: LoadableDemoDestination.basicInClass) {
        Text("Basic Loadable")
      }
      NavigationLink(value: LoadableDemoDestination.restartableInClass) {
        Text("Restartable Loadable")
      }
      NavigationLink(value: LoadableDemoDestination.refreshableInClass) {
        Text("Refreshable Loadable")
      }
      NavigationLink(value: LoadableDemoDestination.interruptsInClass) {
        Text("Loadable Interrupts")
      }
    } footer: {
      Text("See how you can use `LoadableSupport` in an `ObservableObject` or any other class.")
    }
  }
}

#Preview {
  Root().preferredColorScheme(.dark)
}
