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

struct ViewModelDemo: View {
    @StateObject var viewModel = ViewModel()

    var body: some View {
        List {
            switch viewModel.numbers {
            case .absent:
                Section {
                    Button("Load") {
                        viewModel.load()
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
        .animation(.default, value: viewModel.process)
        .animation(.default, value: viewModel.numbers)
        .navigationTitle("ViewModel Demo")
    }

    @ViewBuilder @MainActor
    private var deleteButton: some View {
        LoadingButton("Delete All Numbers", role: .destructive) {
            viewModel.delete()
        }
        .isLoading(viewModel.process.isRunning(.delete))
        .disabled(viewModel.process.isRunning)
        .disabled(viewModel.numbers.data?.isEmpty == true)
    }

    @ViewBuilder @MainActor
    private var resetButton: some View {
        LoadingButton("Reset") {
            viewModel.reset()
        }
        .isLoading(viewModel.process.isRunning(.reset))
    }
}

extension ViewModelDemo {
    @MainActor
    final class ViewModel: ObservableObject, Processable, LoadingSupport {

        enum SingleProcess {
            case delete
            case reset
        }

        @Published var numbers: LoadableState<[Int]> = .absent
        @Published var process: ProcessState<SingleProcess> = .idle

        func load() {
            load(\.numbers) { yield in
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

        func delete() {
            run(\.process, as: .delete) {
                try await Task.sleep(for: .seconds(1))
                self.cancelLoading(\.numbers)
                self.numbers.setValue([])
            }
        }

        func reset() {
            run(\.process, as: .reset) {
                try await Task.sleep(for: .seconds(1))
                self.cancelLoading(\.numbers)
                self.numbers.setAbsent()
                self.process.setIdle()
            }
        }
    }
}

#Preview {
    ViewModelDemo().preferredColorScheme(.dark)
}
