// Copyright 2023 apploft GmbH. All rights reserved.

import Foundation

enum AttemptResult: Sendable {
    case attemptAgain
    case attemptCompleted
}

struct TooManyAttemptsError: Swift.Error, Sendable {}

/// Performs the given block until completion, retrying until a limit has been reached.
///
/// - Parameters:
///   - allowedRetries: The number of allowed retries.
///   - retryDelay: The delay between attempts.
///   - block: The block to perform
@available(iOS 16.0, *)
@MainActor func attemptRepeatedly(
    withAllowedRetries allowedRetries: Int = 5,
    retryDelay: Duration = .seconds(5),
    _ block: (_ currentAttempt: Int) async -> AttemptResult
) async throws {
    var attempts = 0
    while attempts <= allowedRetries {
        try Task.checkCancellation()
        attempts += 1
        let result = await block(attempts)
        switch result {
        case .attemptAgain:
            try await Task.sleep(for: retryDelay)
        case .attemptCompleted:
            return
        }
    }
    throw TooManyAttemptsError()
}
