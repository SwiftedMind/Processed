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

struct ContentView: View {
    
    enum ProcessKind {
        case save
        case delete
    }

    @Loadable<[Int]> var numbers
    @Process<ProcessKind> var process

    var body: some View {
        List {
            switch numbers {
            case .absent:
                Button("Load") {
                    load()
                }
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            case .error(let error):
                Text("An error occurred: \(error.localizedDescription)")
            case .loaded(let numbers):
                Section {
                    if numbers.isEmpty {
                        Text("No Numbers Found")
                    } else {
                        ForEach(numbers, id: \.self) { number in
                            Text(String(number))
                        }
                    }
                }
                Section {
                    saveButton
                    deleteButton
                }
            }
        }
        .animation(.default, value: process)
        .animation(.default, value: numbers)
    }

    @ViewBuilder @MainActor
    private var saveButton: some View {
        LoadingButton("Save") {
            save()
        }
        .isLoading(process.isRunning(.save))
        .disabled(process.isRunning)
    }

    @ViewBuilder @MainActor
    private var deleteButton: some View {
        LoadingButton("Delete", role: .destructive) {
            delete()
        }
        .isLoading(process.isRunning(.delete))
        .disabled(process.isRunning)
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

    @MainActor func save() {
        $process.run(.save) {
            // Simulate saving
            try await Task.sleep(for: .seconds(2))
        }
    }

    @MainActor func delete() {
        $process.run(.delete) {
            try await Task.sleep(for: .seconds(2))
            numbers.setValue([])
        }
    }
}

#Preview {
    ContentView()
}
