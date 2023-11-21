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

@propertyWrapper public struct TaskIdentifier<ID>: DynamicProperty where ID: Equatable {
  @State private var id: ID
  
  public var wrappedValue: ID {
    id
  }
  
  public var projectedValue: Access {
    .init(id: $id)
  }
  
  public init(wrappedValue: ID) {
    self._id = .init(initialValue: wrappedValue)
  }
  
  public init() where ID == UUID {
    self._id = .init(initialValue: .init())
  }
}

extension TaskIdentifier {
  public struct Access {
    @Binding var id: ID
    
    fileprivate init(id: Binding<ID>) {
      self._id = id
    }
    
    public func update(with newId: ID) {
      id = newId
    }
    
    public func update() where ID == UUID {
      id = .init()
    }
  }
}
