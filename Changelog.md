# Changelog
## 2.0.0

> [!Warning]
> This is a release that introduces breaking changes, due to a few unfortunate bugs in 1.0.0. The migration process should not be complicated, though. You can read more about it in the [migration guide](Migration.md).

### New

- In the closures passed to the methods of `ProcessSupport` and `LoadableSupport`, you now don't need to provide explicit `self` anymore, since those closures are simply passed into a `Task`, so reference cycles are no real concern
- Added concept of "interrupts" for both `@Loadable` and `@Process` (as well as their protocol counterparts)
- The closures passed to the `run` methods of the  `ProcessSupport` protocol are now isolated to the `MainActor`
- Added new method `LoadableState<Value>.map(transform:)` to allow convenient mapping of loadable values.
- Added new properties to the projected values of `@Loadable` and `@Process` that give access to a SwiftUI binding to the underlying `LoadableState` and `ProcessState`: `$process.binding` and `$loadable.binding`.
- Added `@TaskIdentifier` property wrapper, which is a convenience wrapper around a `UUID` SwiftUI state that helps with task restarts, e.g. `.task(id: taskIdentifier) { ... }`
- Reworked the demo app and fixed a few bugs and issues
- The demo app now has more examples: `Restartable Loadable`, `Refreshable Loadable`, `Process Interrrupts`, `Loadable Interrupts` and `Failure Alert Process`
- Added error types `ResetProcess` and `ResetLoadable` that can be thrown to reset a process or loadable
- Added typealias `typealias SingleProcessState = ProcessState<SingleProcess>` for convenience

### Changed

- Renamed generic process type `ProcessID` to `ProcessKind` to better communicate its purpose. This should not affect your code at all. 

### Fixed

- Removed redundancies in the `ProcessSupport` protocol code to simplify implementation
- Fixed incorrect `CancelProcess` and `CancelLoadable` error behavior in `ProcessSupport` and `LoadableSupport`; they used to perform a reset instead of a cancel
- Added a missing `Task` `priority` argument in an overload of the `Process.run` method
- Fixed a few typos in the documentation.

## 1.0.0

Initial release
