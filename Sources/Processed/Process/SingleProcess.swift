// swiftformat:disable all
// Copyright © elvah. All rights reserved.

import SwiftUI

/// An identifier for a unique process.
public struct SingleProcess: Equatable, Sendable {
	/// The identifier for the process.
	var id: String
	/// The date when the process was initialized.
	var initializedAt: Date

	/// Initializes a new unique process.
	/// - Parameters:
	///   - id: The unique identifier for the process. Defaults to a new UUID.
	///   - initializedAt: The date when the process was initialized. Defaults to current date and
	/// time.
	public init(id: String = UUID().uuidString, initializedAt: Date = Date()) {
		self.id = id
		self.initializedAt = initializedAt
	}
}

extension SingleProcess: CustomDebugStringConvertible {
	public var debugDescription: String {
		"\(id)"
	}
}
