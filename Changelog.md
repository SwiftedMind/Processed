# Changelog
## 2.0.0 (in development)

- **New** - In the closures passed to the methods of `ProcessSupport` and `LoadableSupport`, you now don't need to provide explicit `self` anymore, since those closures are simply passed into a `Task`, so reference cycles are no real concern
- **New** -  Added oncept of "interrupts" for both `@Loadable` and `@Process` (as well as their protocol counterparts); see more [here](TODO)
- **New** -  The examples app now has more examples; for example `Restartable Loadable` and `Refreshable Loadable`
- **New** -  `ResetProcess` and `ResetLoadable` error types that can be thrown to reset a process or loadable
- **New** - Added typealias `typealias SingleProcessState = ProcessState<SingleProcess>` for convenience
- **New** -  Reworked the examples app and fixed a few bugs and issues
- **New** - The closures passed to the `run` methods of the  `ProcessSupport` protocol are now isolated to the `MainActor`
- **Fixed** - Removed redundancies in the `ProcessSupport` protocol to simplify implementation
- **Fixed** - Fixed incorrect `CancelProcess` and `CancelLoadable` error behavior in `ProcessSupport` and `LoadableSupport`; they used to perform a reset instead of a simpe cancel
- **Fixed** -  Added a missing `Task` `priority` argument in an overload of the `Process.run` method
- **Fixed** -  Fixed a few typos in the documentation.
