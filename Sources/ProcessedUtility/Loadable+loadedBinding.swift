// By Dennis Müller

import OSLog
import Processed
import SwiftUI

public extension Loadable.Binding {
  /// Returns a binding to the associated value stored in the underlying `Loadable.loaded(value)` case. If that value
  /// does not exist (for example, if the loadable is not in the `.loaded` state), `nil` is returned instead.
  ///
  /// You can pass this to a view that only wants to modify the _loaded data_ of the loadable without needing to change
  /// its state.
  ///
  /// - Important: It is your responsibility to make sure the loadable stays in the `.loaded` state for the entirety
  /// of this binding's existence. Any other state will cause the `set` closure to be a no-op.
  var loadedBinding: Binding<Value>? {
    guard let data = state.data else { return nil }
    return Binding<Value> {
      data
    } set: { newValue in
      guard case .loaded = state else {
        return
      }
      state = .loaded(newValue)
    }
  }
}
