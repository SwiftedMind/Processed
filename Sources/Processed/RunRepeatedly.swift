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

import Foundation

public enum AttemptResult: Sendable {
    case attemptAgain
    case attemptCompleted
}

public struct TooManyAttemptsError: Swift.Error, Sendable {}

/// Performs the given block until completion, retrying until a limit has been reached.
///
/// - Parameters:
///   - allowedRetries: The number of allowed retries.
///   - retryDelay: The delay between attempts.
///   - block: The block to perform
@available(iOS 16.0, *)
@MainActor public func runRepeatedly(
    allowedAttempts: Int = 5,
    retryDelay: Duration = .seconds(5),
    _ block: (_ currentAttempt: Int) async -> AttemptResult
) async throws {
    var currentAttempt = 1
    while currentAttempt <= allowedAttempts {
        try Task.checkCancellation()
        let result = await block(currentAttempt)
        switch result {
        case .attemptAgain:
            try await Task.sleep(for: retryDelay)
            currentAttempt += 1
        case .attemptCompleted:
            return
        }
    }
    throw TooManyAttemptsError()
}
