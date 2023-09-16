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

    enum Destination: Hashable, CaseIterable {
        case viewDemo
        case viewModelDemo

        var title: String {
            switch self {
            case .viewDemo: "View Demo"
            case .viewModelDemo: "ViewModel Demo"
            }
        }

        var description: String {
            switch self {
            case .viewDemo: "See how you can use the @Loadable and @Process property wrappers directly in your views."
            case .viewModelDemo: "See how to use LoadableState and ProcessState in an ObservableObject."
            }
        }
    }

    @State var path: [Destination] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(Destination.allCases, id: \.self) { destination in
                    NavigationLink(value: destination) {
                        VStack(alignment: .leading) {
                            Text(destination.title)
                            Text(destination.description)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("Demos")
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .viewDemo:
                    ViewDemo()
                case .viewModelDemo:
                    ViewModelDemo()
                }
            }
        }
    }
}

#Preview {
    Root().preferredColorScheme(.dark)
}
