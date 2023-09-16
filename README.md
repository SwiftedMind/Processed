<p align="center">
  <img width="200" height="200" src="https://github.com/SwiftedMind/Processed/assets/7083109/39b3e3cc-b866-4afc-8f9a-8aa5df4392ec">
</p>

# Processed

![GitHub tag (with filter)](https://img.shields.io/github/v/tag/SwiftedMind/Processed)
![GitHub](https://img.shields.io/github/license/SwiftedMind/Processed)



README is a work in progress.

```swift
import SwiftUI
import Processed

struct ViewDemo: View {
    
    enum SingleProcess {
        case delete
        case reset
    }

    @Loadable var numbers: LoadableState<[Int]>
    @Process<SingleProcess> var process

    var body: some View {
        List {
            switch numbers {
            case .absent:
                Section {
                    Button("Load") {
                        load()
                    }
                }
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            case .error(let error):
                Text("An error occurred: \(error.localizedDescription)")
            case .loaded(let numbers):
                Section {
                    deleteButton
                    resetButton
                }
                Section {
                    if numbers.isEmpty {
                        Text("No Numbers Found")
                    } else {
                        ForEach(numbers, id: \.self) { number in
                            Text(String(number))
                        }
                    }
                }
            }
        }
        .animation(.default, value: process)
        .animation(.default, value: numbers)
        .navigationTitle("View Demo")
    }

    @ViewBuilder @MainActor
    private var deleteButton: some View {
        LoadingButton("Delete All Numbers", role: .destructive) {
            delete()
        }
        .isLoading(process.isRunning(.delete))
        .disabled(process.isRunning)
        .disabled(numbers.data?.isEmpty == true)
    }

    @ViewBuilder @MainActor
    private var resetButton: some View {
        LoadingButton("Reset") {
            reset()
        }
        .isLoading(process.isRunning(.reset))
    }

    @MainActor func load() {
        $numbers.load { yield in
            var numbers: [Int] = []
            for await number in [1, 2, 3, 4, 5].publisher.values {
                try await Task.sleep(for: .seconds(1))
                numbers.append(number)
                yield(numbers)
            }
            try await Task.sleep(for: .seconds(1))
            yield(numbers.shuffled())
        }
    }

    @MainActor func delete() {
        $process.run(.delete) {
            try await Task.sleep(for: .seconds(1))
            $numbers.cancel()
            numbers.setValue([])
        }
    }

    @MainActor func reset() {
        $process.run(.reset) {
            try await Task.sleep(for: .seconds(1))
            $numbers.cancel()
            numbers.setAbsent()
            process.setIdle()
        }
    }
}
```

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