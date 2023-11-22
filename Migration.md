# Migration Guide

## Migrate to 2.0.0

Processed 2.0.0 is mostly an update adding new, backwards-compatible features.
However, there are some behavioral differences that warrant a new major release.

### Cancel behavior

When running a loadable or process task using the `ProcessSupport` or `LoadableSupport` protocols, 
cancelling those task was implemented wrongly in 1.0.0 and did not only cancel the tasks, but also
reset them, which is incorrect. This has been fixed with 2.0.0. 
If you relied to the reset behavior, you can use the new `ResetProcess` and `ResetLoadable` errors
instead.

### `ProcessSupport` method closures now properly `@MainActor` isolated

All the closures you pass to the methods of the `ProcessSupport` or `LoadableSupport` protocols
are now properly isolated to the `MainActor`. In 1.0.0, they were not. In the future, I might try
and loosen this restriction but that requires some work internally.
