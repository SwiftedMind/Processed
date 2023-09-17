
<p align="center">
  <img width="200" height="200" src="https://github.com/SwiftedMind/Processed/assets/7083109/39b3e3cc-b866-4afc-8f9a-8aa5df4392ec">
</p>

# Processed

![GitHub tag (with filter)](https://img.shields.io/github/v/tag/SwiftedMind/Processed)
![GitHub](https://img.shields.io/github/license/SwiftedMind/Processed)

Processed is a lightweight wrapper around loading states in SwiftUI.

```swift
struct DemoView: View {
  @Loadable<[Int]> var numbers
  
  @MainActor func loadNumbers() {
    $numbers.load {
      try await Task.sleep(for: .seconds(2))
      return [0, 1, 2, 42, 73]
    }
  }
  
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
      case .error(let error): 
        Text("\(error.localizedDescription)")
      case .loaded(let numbers):
        ForEach(numbers, id: \.self) { number in
          Text(String(number))
        }
      }
    }
    .animation(.default, value: numbers)
  }
}
```

- [Installation](#installation)
- [Documentation](#documentation)
- [Background](#background)
- **[Get Started](#get-started)**
	- [LoadableState](#loadablestate)
 	- [ProcessState](#processstate)
- [Example Apps](#example-apps)
- [License](#license)

## Installation

Prcoessed supports iOS 15+, macOS 13+, watchOS 8+ and tvOS 15+ and visionOS 1+.

### Swift Package

Add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/SwiftedMind/Processed", from: "0.4.0")
```

### Xcode project

Go to `File` > `Add Packages...` and enter the URL "https://github.com/SwiftedMind/Processed" into the search field at the top right. Puddles should appear in the list. Select it and click "Add Package" in the bottom right.

## Documentation

_Coming soon_

## Background

Apps need to handle loading, error and success states in a lot of places, to perform generic processes like logging in, saving, or deleting something, or to fetch and prepare data for the user. Therefore, it is useful to define some kind of `enum` that drives the UI:

```swift
enum LoadingState<Value> {
  case absent
  case loading
  case error(Error)
  case loaded(Value)
}

// Optionally, you could define a similar ProcessState enum for generic processes without a return value
```

You would then use that in a SwiftUI view like this (or inside a view model, if you prefer to keep state out of the views):

```swift
struct DemoView: View {
  @State var numbers: LoadingState<[Int]> = .absent
  var body: some View {
    List {
      switch numbers {
        /* Loading, Error and Success UI */
      }
  }
}
```

This is really handy to make sure your UI is consistent with the current state of your data. However, in almost any case, a loading process like this is tightly coupled to an asynchronous task that actually runs the process without blocking the UI. So you would need another state in your view or view model:

```swift
struct DemoView: View {
  @State var numbers: LoadingState<[Int]> = .absent
  @State var loadingTask: Task<Void, Never>?

  var body: some View {
    List {
      Button("Reload") { reload() }
      switch numbers {
        /* Loading, Error and Success UI */
      }
  }
  
  func reload() {
    /* Reload data */
  }
}
```

The reload method could look something like this:

```swift
func reload() {
  loadingTask?.cancel()
  loadingTask = Task {
    numbers = .loading
    do {
      let fetchedNumbers = try await fetchNumbers() // Imagine this method to fetch the data from somewhere
      numbers = .loaded(fetchedNumbers)
    } catch {
      numbers = .error(error)
    }
  }
}
```

The interesting thing here is that almost everything inside the method is boilerplate. You always have to cancel any previous loading tasks, create a new task, set the `.loading` state and you always have to end with either a `.loaded` state or an `.error` state. The only part that's unique to this specific situation is calling `fetchNumbers()`.

And that's exactly what Processed helps with. It hides that boilerplate behind a set of easy to use types and property wrappers. Let's have a look at how it works.

## Get Started

### LoadableState

Processed defines a `LoadableState` enum that can be used to represent the loading state of some data. It also comes with a lot of handy convenient properties and methods, like `.isLoading`, `.setLoading`, `.data` etc.

```swift
enum LoadableState<Value> {
  case absent
  case loading
  case error(Error)
  case loaded(Value)
}
```

Building on top of this type, Processed defines the `@Loadable` property wrapper.

```swift
@propertyWrapper public struct Loadable<Value>: DynamicProperty where Value: Sendable {
  public var wrappedValue: LoadableState<Value> { get nonmutating set }
  public var projectedValue: Loadable<Value>.Binding { get }
  public init(wrappedValue initialState: LoadableState<Value> = .absent)
  public struct Binding { /* ... */ }
}
```

Its `wrappedValue` exposes the underlying `LoadableState`, whereas the `projectedValue` exposes a set of methods to manage the loading of the data. You can use this in any SwiftUI view. Let's look at the example from above, but rewritten using `@Loadable`:

```swift
struct DemoView: View {
  @Loadable<[Int]> var numbers
  
  var body: some View {
    List {
      Button("Reload") { loadNumbers() }
      .disabled(numbers.isLoading)
      switch numbers {
      case .absent: 
        EmptyView()
      case .loading: 
        ProgressView()
      case .error(let error): 
        Text("\(error.localizedDescription)")
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
      try await fetchNumbers()
    }
  }
}
```

The `$numbers.load` does a few things. It cancels any previous tasks, starts a new one and sets the state to `.loading`. It then runs the closure and uses its result to set the `.loaded` state or a thrown error to set the `.error` state. All this is hidden behind this convenient call to one single method.

Additionally, `@Loadable` also has another overload of the `load` method, that let's you yield multiple results. This is useful if you have a stream of data that you want to send to the UI:

```swift
@MainActor func loadNumbers() {
  $numbers.load { yield in
    for try await numbers in streamNumbers() {
      yield(.loaded(numbers)
    }
  }
}
```

To cancel an ongoing task, simply call `$numbers.cancel()` or throw a `CancelLoadable()` error from inside the closure. To fully reset the state, there is also the `$numbers.reset()` method you can use.

<details>
  <summary>Use LoadableState in Classes</summary>
  
 If you prefer to keep your state in a view model, or if you would like to use Processed completeley outside of SwiftUI, you can also do all the things from above inside a class. However, it works slightly different because of the nature of SwiftUI property wrappers (they hold `@State` properties inside, which don't work outside the SwiftUI environment).

```swift
@MainActor final class ViewModel: ObservableObject, ProcessSupport, LoadableSupport {
  // Define the LoadableState enum as a normal @Published property
  @Published var numbers: LoadableState<[Int]> = .absent

  func loadNumbers() {
    // Call the load method from the LoadableSupport protocol
    load(\.numbers) {
      try await self.fetchNumbers()
    }
  }
  
  func loadStreamedNumbers() {
    load(\.numbers) { yield in
      for try await numbers in self.sstreamNumbers() {
        yield(.loaded(numbers)
      }
    }
  }
}
```
</details>

#### Use in Classes


### ProcessState

```swift
// ProcessID is used to identify a process, so that you can share a process state across different tasks
enum ProcessState<ProcessID> {
  case idle
  case running(ProcessID)
  case failed(process: ProcessID, error: Swift.Error)
  case finished(ProcessID)
}
```

`LoadableState` is useful to represent the loading state of some data, while `ProcessState` does the same for generic processes without an actual, direct result.


### In SwiftUI Views

Inside the SwiftUI environment, you can use the `@Process` and `@Loadable` property wrappers for maximum convenience.

### In Classes


## Example Apps

You can find an example app in the `Examples` folder of this repository.

## License

MIT License

Copyright (c) 2023 Dennis Müller and all collaborators

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
