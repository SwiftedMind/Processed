<img width="100" height="100" src="https://github.com/SwiftedMind/Processed/assets/7083109/39b3e3cc-b866-4afc-8f9a-8aa5df4392ec">

# Processed

![GitHub release (with filter)](https://img.shields.io/github/v/release/SwiftedMind/Processed)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSwiftedMind%2FProcessed%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/SwiftedMind/Processed)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSwiftedMind%2FProcessed%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/SwiftedMind/Processed)
![GitHub](https://img.shields.io/github/license/SwiftedMind/Processed)

Processed is a lightweight, automatic loading state handler for SwiftUI, reducing repetitive boilerplate code and improving code readability. It works in views via two property wrappers (`@Loadable` and `@Process`) as well as in arbitrary classes using the `LoadableSupport` and `ProcessSupport` protocols. It also supports full manual state control for situations where the defaults don't work as needed.

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

1. [Installation](#installation)
2. [Documentation](#documentation)
3. [Background](#background)
4. **[Loadable](#loadable)**
	- [Loadable in Classes](#use-processstate-in-classes)
5. **[Process](#process)**
	- [Process in Classes](#use-loadablestate-in-classes)
6. [Advanced Features](#advanced-features)
	- [Interrupts](#interrupts)
7. [Examples](#examples)
8. [License](#license)

## Installation

Processed supports iOS 15+, macOS 13+, watchOS 8+ and tvOS 15+ and visionOS 1+.

### Swift Package

Add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/SwiftedMind/Processed", from: "2.0.0")
```

### Xcode project

Go to `File` > `Add Packages...` and enter the URL "https://github.com/SwiftedMind/Processed" into the search field at the top right. Puddles should appear in the list. Select it and click "Add Package" in the bottom right.

## Documentation

You can find the documentation [here](https://swiftpackageindex.com/SwiftedMind/Processed/documentation/processed).

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
      try await Task.sleep(for: .seconds(2))
      numbers = .loaded([0, 1, 2, 42, 73])
    } catch {
      numbers = .error(error)
    }
  }
}
```

The interesting thing here is that almost everything inside the method is boilerplate. You always have to cancel any previous loading tasks, create a new task, set the `.loading` state and you always have to end with either a `.loaded` state or an `.error` state. The only part that's unique to this specific situation is actually loading the data.

And that's exactly what Processed helps with. It hides that boilerplate behind a set of easy to use types and property wrappers. Let's have a look at how it works.

### Loadable

Processed defines a `LoadableState` enum that can be used to represent the loading state of some data. It also comes with a lot of handy properties and methods, like `.isLoading`, `.setLoading()`, `.data` etc.

```swift
enum LoadableState<Value> {
  case absent
  case loading
  case error(Error)
  case loaded(Value)
}
```

Building on top of this type, Processed defines the `@Loadable` property wrapper, which you can use in a SwiftUI view to automate the loading state and task handling.

```swift
struct DemoView: View {
  @Loadable<[Int]> var numbers // Default state .absent
  // ...
}
```

Here, `numbers` is of type `LoadableState<[Int]>`, meaning you can switch over it and interact with it as you would with any other `enum`. The view will also update whenever the state changes. This gives you full manual control over all states and behaviors, if you need it.

```swift
/* DemoView */
var body: some View {
  List {
    switch numbers {
    case .absent: /* ... */
    case .loading: /* ... */
    case .error(let error): /* ... */
    case .loaded(let numbers): /* ... */
    }
  }
}
```

However, the real benefit comes with the `$`-prefix property `$numbers`. It exposes a few methods that take care of the repetitive boilerplate code we discussed above:

```swift
/* DemoView */
@MainActor func loadNumbers() {
  $numbers.load {
    try await Task.sleep(for: .seconds(2))
    return [42]
  }
}
```

Here, the call to `$numbers.load { ... }` does a few things: 
1. It cancels any previous loading `Tasks`
2. It starts and stores a new `Task`
3. It sets the state to `.loading` (unless the `runSilently` argument is set to `true`)
4.  It calls the closure and waits for either a return value or an error.
	- If a value is returned, it will set the state to `.loaded(theValue)`
	- If an error is thrown, it will set the state to `.error(theError)`

Everything is hidden behind this one simple call, so that you can just focus on actually loading the data.

You can also `yield` multiple values over time:

```swift
/* DemoView */
@MainActor func loadNumbers() {
  $numbers.load { yield in
    var numbers: [Int] = []
    for await number in [42, 73].publisher.values {
      try await Task.sleep(for: .seconds(1))
      numbers.append(number)
      yield(.loaded(numbers))
    }
  }
}
```

Additionally, you can call `load` from an `async` context. When this happens, the loading process will not create its own `Task` internally, but rather simply use the calling `Task`, giving you full control over it:

```swift
/* DemoView */
@MainActor func loadNumbers() {
  self.numbersTask = Task {
    await $numbers.load { // await the loading process
      try await Task.sleep(for: .seconds(2))
      return [42]
    }
    // At this point, the loading process has finished
  }
}
```

And lastly, `@Loadable` also supports cancellation from the outside and inside (in addition to respecting a parent `Task` cancellation):

```swift
$numbers.cancel() // Cancel internal Task
$numbers.reset() // Cancel internal Task and reset state to .absent

// Throw this in the `load` closure, to cancel a loading process from the inside:
throw CancelLoadable()

// Throw this in the `load` closure, to reset a loading process from the inside:
throw ResetLoadable()
```

#### Use `LoadableState` in Classes

If you prefer to keep your state in a view model, or if you would like to use Processed completely outside of SwiftUI, you can also do all the things from above inside a class. However, the syntax is slightly different because of the nature of SwiftUI property wrappers (they hold `@State` properties inside, which don't work outside the SwiftUI environment).

However, it's still really easy: You have to conform your class to the `LoadableSupport` protocol that implements the same `load`, `cancel` and `reset`  methods as the `@Loadable` property wrapper, but this time defined on the class itself:

```swift
@MainActor final class ViewModel: ObservableObject, LoadableSupport {
  // Define the LoadableState enum as a normal @Published property
  @Published var numbers: LoadableState<[Int]> = .absent

  func loadNumbers() {
    // Call the load method from the LoadableSupport protocol
    load(\.numbers) {
      try await Task.sleep(for: .seconds(2))
      return [42]
    }
  }
  
  func loadStreamedNumbers() {
    // Call the load method that yields results from the LoadableSupport protocol
    load(\.numbers) { yield in
      var numbers: [Int] = []
      for await number in [42, 73].publisher.values {
        try await Task.sleep(for: .seconds(1))
        numbers.append(number)
        yield(.loaded(numbers))
      }
    }
  }

  func cancelLoading() {
    cancel(\.numbers)
  }
}
```

### Process

Processed also defines a `ProcessState` enum that can be used to represent the state of a generic process, like logging in, saving something or a deletion. Just as `LoadableState`, it comes with a lot of handy properties and methods, like `.isRunning`, `.setFinished()`, `.error`, etc.

```swift
enum ProcessState<ProcessKind> {
  case idle
  case running(ProcessKind)
  case failed(process: ProcessKind, error: Swift.Error)
  case finished(ProcessKind)
}
```

Building on top of this type, Processed defines the `@Process` property wrapper, which you can use in a SwiftUI view to automate the process state and task handling.

```swift
struct DemoView: View {
  @Process var saveData // Compiler infers Process<SingleProcess> for single-purpose process states
  // ...
}
```

Here, `saveData` is of type `ProcessState<SingleProcess>`, meaning you can switch over it and interact with it as you would with any other `enum`. The view will also update whenever the state changes. This gives you full manual control over all states and behaviors, if you need it.

```swift
/* DemoView */
var body: some View {
  List {
    switch saveData {
    case .idle: /* ... */
    case .running: /* ... */
    case .failed(_, let error): /* ... */
    case .finished: /* ... */
    }
  }
}
```

However, just like with `@Loadable`, the real benefit comes with the `$`-prefix property `$saveData`. It also exposes a few methods that take care of the repetitive boilerplate code we discussed above:

```swift
/* DemoView */
@MainActor func save() {
  $saveData.run {
    try await saveToDisk()
  }
}
```

Here, the call to  `$saveData.run { ... }`  does a few things, pretty much identical to what `@Loadable` does, just with semantics better fitting a generic process without a return value:

1.  It cancels any previous loading  `Tasks`
2.  It starts and stores a new  `Task`
3.  It sets the state to  `.running`  (unless the  `runSilently`  argument is set to  `true`)
4.  It calls the closure and waits for either a return or an error.
    -   If the closure returns, it will set the state to  `.finished`
    -   If an error is thrown, it will set the state to  `.failed(theError)`

Everything is hidden behind this one simple call, so that you can just focus on actually loading the data.

You can also manage multiple kinds of processes through the same state. This is useful if you have multiple processes that don't run in parallel. In the example above, the generic parameter of the `ProcessState` enum is automatically inferred to be `SingleProcess`, which is a helper type to make it easier to work with processes that only have a single purpose. Specifying your own `ProcessKind` is really easy, too! Let's modify the example slightly by adding a deletion option:

```swift
enum ProcessKind {
  case save
  case delete
}

struct DemoView: View {
  @Process<ProcessKind> var process // Specify multiple purposes of this process state

  @MainActor func save() {
    $process.run(.save) { // Run a save process
      try await saveToDisk()
    }
  }
  
  @MainActor func delete() {
    $process.run(.delete) {  // Run a delete process
      try await deleteFromDisk()
    }
  }

  var body: some View {
    List {
      switch saveData {
      case .idle: /* ... */
      case .running(let process): /* ... */ // Identify the process
      case .failed(let process, let error): /* ... */ // Identify the process
      case .finished(let process): /* ... */ // Identify the process
      }
    }
  }
}
```

Additionally, you can call `run` from an `async` context. When this happens, `@Process` will not create its own `Task` internally, but rather simply use the calling `Task`, giving you full control over it:

```swift
/* DemoView */
@MainActor func save() {
  self.processTask = Task {
    await $process.run(.save) { // await the process
      try await saveToDisk()
    }
    // At this point, the process has finished
  }
}
```

And lastly, `@Process` also supports cancellation from the outside and inside (in addition to respecting a parent `Task` cancellation):

```swift
$process.cancel() // Cancel internal Task
$process.reset() // Cancel internal Task and reset state to .absent

// Throw this in the `run` closure, to cancel a process from the inside:
throw CancelProcess()

// Throw this in the `run` closure, to reset a process from the inside:
throw ResetProcess()
```

#### Use `ProcessState` in Classes

Just as with `LoadableState`, you can also do all the things from above inside a class. You simply have to conform your class to the `ProcessSupport` protocol that implements the same `run`, `cancel` and `reset`  methods as the `@Process` property wrapper, but this time defined on `self`:

```swift
enum  ProcessKind {
  case save
  case delete
}

@MainActor final class ViewModel: ObservableObject, ProcessSupport {
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
 
  func cancelLoading() {
    cancel(\.process)
  }
}
```

## Advanced Features

### Interrupts

All of the `load` and `run` methods from above have overloads to add something called "interrupts". An interrupt is a closure that is called in parallel, during the (loading) process, allowing you to run logic based on how long that process takes. This makes it easy to add a timeout when the process takes too long or fade in a view that says "Loading takes a bit longer than expected". Here is an example:

```swift
@Loadable var numbers: LoadableState<[Int]>
@State var showLoadingDelay = false
// ...
@MainActor func loadWithTimeout() {
 $numbers.load(interrupts: [.seconds(2), .seconds(3)]) {
  try await Task.sleep(for: .seconds(10))
  return [42]
 } onInterrupt: { accumulatedDelay in
  switch accumulatedDelay {
  case .seconds(5):
   throw TimeoutError()
  default:
   showLoadingDelay = true
  }
 }
}
```

## Examples

You can find a demo project in the [Examples](https://github.com/SwiftedMind/Processed/tree/main/Examples) folder of this repository. In there, you will find a selection of examples and demonstrations you can use to get started.

| App  | Simple Process Demo | Basic Loadable Demo |
| ------------- | ------------- | ------------- |
| ![RocketSim_Screenshot_iPhone_15_Pro_2023-11-21_23 05 12](https://github.com/SwiftedMind/Processed/assets/7083109/efdbc741-77a4-44cd-a4aa-e1ebeff3042b)
 | ![RocketSim_Screenshot_iPhone_15_Pro_2023-11-21_23 05 23](https://github.com/SwiftedMind/Processed/assets/7083109/5f7e4971-44b9-453e-ad4a-caefa2680860)
 | ![RocketSim_Screenshot_iPhone_15_Pro_2023-11-21_23 05 36](https://github.com/SwiftedMind/Processed/assets/7083109/9a418c27-4c05-4c6c-9dba-b8b89502efed)
 |

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
