
<p align="center">
  <img width="200" height="200" src="https://github.com/SwiftedMind/Processed/assets/7083109/39b3e3cc-b866-4afc-8f9a-8aa5df4392ec">
</p>

# Processed

![GitHub tag (with filter)](https://img.shields.io/github/v/tag/SwiftedMind/Processed)
![GitHub](https://img.shields.io/github/license/SwiftedMind/Processed)

Processed is a lightweight wrapper around loading states in SwiftUI, providing 

with the goal to reduce repeated writing of boilerplate code and task management

It comes with two enums `LoadableState` and `ProcessState` 

It works in views as well as classes.

```swift
struct DemoView: View {
  @Loadable<[Int]> var numbers
  var body: some View {
    List {
      Button("Load Numbers") {
        loadNumbers()
      }.disabled(numbers.isLoading)
      switch numbers {
      case .absent: EmptyView()
      case .loading: ProgressView()
      case .error(let error): Text("\(error.localizedDescription)")
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

```

- [Installation](#installation)
- [Documentation](#documentation)
- [Get Started](#get-started)
- [Example Apps](#example-apps)
- [License](#license)

## Installation

Prcoessed supports iOS 15+, macOS 13+, watchOS 8+ and tvOS 15+ and visionOS 1+.

### Swift Package

Add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/SwiftedMind/Processed", from: "0.3.0")
```

### Xcode project

Go to `File` > `Add Packages...` and enter the URL "https://github.com/SwiftedMind/Processed" into the search field at the top right. Puddles should appear in the list. Select it and click "Add Package" in the bottom right.

## Documentation

_Coming soon_

## Get Started

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

The interesting thing here is that almost everything inside the method is boilerplate. You always have to cancel any previous loading tasks, you always have to set the `.loading` state and you always have to end with either a `.loaded` state or an `.error` state. The only part that's unique to this specific situation is calling `fetchNumbers()`.

And that's exactly what Processed helps with. It hides this boilerplate behind a set of easy to use types and property wrappers. Let's have a look at how it works.

### LoadableState

### ProcessState

Processed consists of two property wrappers: `@Process` and `@Loadable`, both of which you can use inside SwiftUI

### In SwiftUI Views

Inside the SwiftUI environment, you can use the `@Process` and `@Loadable` property wrappers for maximum convenience.


### In an`ObservableObject`



```swift
struct DemoView: View {
  @Loadable<[Int]> var numbers
  var body: some View {
    List {
      Button("Load Numbers") {
        loadNumbers()
      }.disabled(numbers.isLoading)
      switch numbers {
      case .absent: EmptyView()
      case .loading: ProgressView()
      case .error(let error): Text("\(error.localizedDescription)")
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

```

## Example Apps

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
