//// Errors that can cause a test step to fail.

/// Why a step failed.
pub type Error {
  /// An `expect` assertion did not hold before its timeout ran out.
  AssertionFailed(message: String)
  /// A Playwright action (click, navigation, ...) did not complete in time.
  Timeout(message: String)
  /// Playwright reported some other error, e.g. a failed navigation or a
  /// locator that matched more than one element.
  PlaywrightError(message: String)
  /// The test was failed explicitly with `step.fail`.
  Failed(message: String)
  /// The test panicked, e.g. through a failing `assert` or `let assert`.
  Panic(message: String)
}

/// A human readable description of the error.
pub fn to_string(error: Error) -> String {
  case error {
    AssertionFailed(message) -> "Assertion failed: " <> message
    Timeout(message) -> "Timeout: " <> message
    PlaywrightError(message) -> "Playwright error: " <> message
    Failed(message) -> "Failed: " <> message
    Panic(message) -> "Panic: " <> message
  }
}
