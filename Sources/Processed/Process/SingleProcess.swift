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

/// An identifier for a unique process.
public struct SingleProcess: Equatable, Sendable {
  /// The identifier for the process.
  var id: String
  /// The date when the process was initialized.
  var initializedAt: Date
  
  /// Initializes a new unique process.
  /// - Parameters:
  ///   - id: The unique identifier for the process. Defaults to a new UUID.
  ///   - initializedAt: The date when the process was initialized. Defaults to current date and time.
  public init(id: String = UUID().uuidString, initializedAt: Date = .now) {
    self.id = id
    self.initializedAt = initializedAt
  }
}

extension SingleProcess: CustomDebugStringConvertible {
  public var debugDescription: String {
    "\(id)"
  }
}
