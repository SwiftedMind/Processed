
<p align="center">
  <img width="200" height="200" src="https://github.com/SwiftedMind/Processed/assets/7083109/39b3e3cc-b866-4afc-8f9a-8aa5df4392ec">
</p>

# Processed

![GitHub tag (with filter)](https://img.shields.io/github/v/tag/SwiftedMind/Processed)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSwiftedMind%2FProcessed%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/SwiftedMind/Processed)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSwiftedMind%2FProcessed%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/SwiftedMind/Processed)
![GitHub](https://img.shields.io/github/license/SwiftedMind/Processed)

Processed is a lightweight wrapper around the handling of loading states in SwiftUI, reducing repetitive boilerplate code and improving code readability. It works in SwiftUI views via two property wrappers (`@Loadable` and `@Process`) as well as in arbitrary classes using the `LoadableSupport` and `ProcessSupport` protocols. It also support full manual state control for situations where the defaults don't work as needed.

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
  }
}
```

## Content

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

You can find the documentation here: [https://swiftpackageindex.com/SwiftedMind/Processed/0.5.0/documentation/processed](https://swiftpackageindex.com/SwiftedMind/Processed/0.5.0/documentation/processed)

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
      Button("Reload") { loadNumbers() }
      switch numbers {
        /* Loading, Error and Success UI */
      }
  }
  
  func loadNumbers() {
    /* Reload data */
  }
}
```

The `loadNumbers` method could look something like this:

```swift
func loadNumbers() {
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

Processed defines a `LoadableState` enum that can be used to represent the loading state of some data. It also comes with a lot of handy properties and methods, like `.isLoading`, `.setLoading()`, `.data` etc.

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
  @propertyWrapper public struct Binding { /* ... */ }
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

To cancel an ongoing task, simply call `$numbers.cancel()` or throw a `CancelLoadable()` error from inside the closure. To fully reset the state, there is also a `$numbers.reset()` method you can use.

<details>
  <summary>Use LoadableState in Classes</summary>
  
If you prefer to keep your state in a view model, or if you would like to use Processed completely outside of SwiftUI, you can also do all the things from above inside a class. However, it works slightly differently because of the nature of SwiftUI property wrappers (they hold `@State` properties inside, which don't work outside the SwiftUI environment).

You simply have to conform your class to the `LoadableSupport` protocol that implements the same `load`, `cancel` and `reset`  methods as the `@Loadable` property wrapper, but this time defined on `self`:

```swift
@MainActor final class ViewModel: ObservableObject, LoadableSupport {
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

### ProcessState

Processed also defines a `ProcessState` enum that can be used to represent the state of a generic process, like logging in, saving something or a deletion. Just as `LoadableState`, it comes with a lot of handy properties and methods, like `.isRunning`, `.setFinished()`, `.error`, etc.

```swift
enum ProcessState<ProcessID> {
  case idle
  case running(ProcessID)
  case failed(process: ProcessID, error: Swift.Error)
  case finished(ProcessID)
}
```

Building on top of this type, Processed defines the `@Process` property wrapper:

```swift
@propertyWrapper public struct Process<ProcessID>: DynamicProperty where ProcessID: Equatable, ProcessID: Sendable {
  public var wrappedValue: ProcessState<ProcessID> { get nonmutating set }
  public var projectedValue: Binding { get }
  public init(initialState: ProcessState<ProcessID> = .idle)
  public init() where ProcessID == SingleProcess
  @propertyWrapper public struct Binding { /* ... */ }
}
```

It works similarly to `@Loadable`, but with slightly better fitting semantics around type and method names. 

Let's look at an example:

```swift
struct DemoView: View {
  @Process var saving
  
  var body: some View {
    List {
      Button("Save") { save() }
      .disabled(numbers.isLoading)
      switch saving {
      case .idle: 
        Text("Idle")
      case .running: 
        Text("Saving")
      case .failed(_, let error): 
        Text("\(error.localizedDescription)")
      case .finished:
        Text("Finished Saving")
      }
    }
  }
  
  @MainActor func save() {
    $saving.run {
      try await save()
    }
  }
}
```

Just as with `@Loadable`, you can cancel an ongoing task  by calling `$saving.cancel()` or throw a `CancelProcess()` error from inside the closure. To fully reset the state, there is also a `$saving.reset()` method you can use.


#### Process Identification

`ProcessState` is generic over `ProcessID`, which is some value that identifies a specific process. This is useful if you have multiple processes that don't run in parallel and should be managed by a single state.

In the above example, the generic `ProcessID` is automatically inferred to be `SingleProcess`, which is a helper type to make it easier to work with processes that only have a single identification. Specifying your own `ProcessID` is really easy, too! Let's modify the example slightly by adding a deletion option:

```swift
struct DemoView: View {

  enum  ProcessKind {
    case save
    case delete
  }

  @Process var process
  
  var body: some View {
    List {
      Button("Save") { save() }
      .loading(process.isRunning(.save)) // Helper modifier to show a loading indicator on the button
      .disabled(process.isRunning) // Disable if either process is running
      Button("Delete") { delete() }
      .loading(process.isRunning(.delete)) // Helper modifier to show a loading indicator on the button
      .disabled(process.isRunning) // Disable if either process is running
      switch process {
      case .idle: 
        Text("Idle")
      case .running(let process): 
        Text("Running \(process)")
      case .failed(let process, let error): 
        Text("\(process): \(error.localizedDescription)")
      case .finished(let process):
        Text("Finished \(process)")
      }
    }
  }
  
  @MainActor func save() {
    $process.run(.save) {
      try await save()
    }
  }
  
  @MainActor func delete() {
    $process.run(.delete) {
      try await delete()
    }
  }
}
```

<details>
  <summary>Use ProcessState in Classes</summary>
  
Just as with `LoadableState`, you can also do all the things from above inside a class.

You simply have to conform your class to the `ProcessSupport` protocol that implements the same `run`, `cancel` and `reset`  methods as the `@Process` property wrapper, but this time defined on `self`:

```swift
@MainActor final class ViewModel: ObservableObject, ProcessSupport {

  enum  ProcessKind {
    case save
    case delete
  }

  // Define the Process enum as a normal @Published property
  @Published var process: Process<ProcessKind> = .idle

  func save() {
    // Call the run method from the ProcessSupport protocol
    run(\.process, as: .save) {
      try await save()
    }
  }
  
  func delete() {
    // Call the run method from the ProcessSupport protocol
    run(\.process, as: .delete) {
      try await delete()
    }
  }
}
```
</details>

## Example Apps

You can find an example app in the [Examples](https://github.com/SwiftedMind/Processed/tree/main/Examples) folder of this repository.

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
