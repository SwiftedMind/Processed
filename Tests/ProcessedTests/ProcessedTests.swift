import XCTest
@testable import Processed

@available(iOS 16.0, *)
final class ProcessedTests: XCTestCase {
    func testRunRepeatedly() async throws {
        var attempts = 0
        let expectedAttempts = 5
        do {
            try await runRepeatedly(allowedAttempts: expectedAttempts, retryDelay: .zero) { currentAttempt in
                attempts = currentAttempt
                return .attemptAgain
            }
        } catch is TooManyAttemptsError {
            XCTAssertEqual(attempts, expectedAttempts)
        } catch {
            XCTFail()
        }
    }
}
