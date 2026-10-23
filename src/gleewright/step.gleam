//// A `Step` is an asynchronous action in a test, such as a click or an
//// assertion, that either succeeds with a value or fails with an `Error`.
////
//// Chain steps with `use` and `try`. The test body returns the last step:
////
//// ```gleam
//// gleewright.it("signs in", fn(page) {
////   use _ <- step.try(page.goto(page, "/login"))
////   use title <- step.try(page.title(page))
////   use _ <- step.try(expect.equal(title, "Sign in"))
////   page.get_by_role(page, role.Button) |> locator.click
//// })
//// ```
////
//// As soon as one step fails, the rest of the chain is skipped and the test
//// fails with that step's error.
////
//// Reusable setup, such as signing in, is an ordinary function that takes
//// the rest of the test as a callback:
////
//// ```gleam
//// fn signed_in(page: Page, next: fn() -> Step(a)) -> Step(a) {
////   use _ <- step.try(page.goto(page, "/login"))
////   use _ <- step.try(page.get_by_label(page, "Email") |> locator.fill("me@example.com"))
////   use _ <- step.try(page.get_by_role_named(page, role.Button, "Sign in") |> locator.click)
////   next()
//// }
////
//// gleewright.it("shows the dashboard", fn(page) {
////   use <- signed_in(page)
////   expect.page(page) |> expect.to_have_url("/dashboard")
//// })
//// ```

import gleam/javascript/promise.{type Promise}
import gleam/list
import gleewright/error.{type Error}

/// An asynchronous action that succeeds with a value of type `a`, or fails
/// with an `Error`.
pub opaque type Step(a) {
  Step(promise: Promise(Result(a, Error)))
}

/// Run a step, and if it succeeds pass its value on to the next one.
pub fn try(step: Step(a), next: fn(a) -> Step(b)) -> Step(b) {
  promise.await(step.promise, fn(result) {
    case result {
      Ok(value) -> next(value).promise
      Error(error) -> promise.resolve(Error(error))
    }
  })
  |> Step
}

/// Transform the value produced by a step.
pub fn map(step: Step(a), with transform: fn(a) -> b) -> Step(b) {
  promise.map(step.promise, fn(result) {
    case result {
      Ok(value) -> Ok(transform(value))
      Error(error) -> Error(error)
    }
  })
  |> Step
}

/// A step that immediately succeeds with the given value.
pub fn succeed(value: a) -> Step(a) {
  Step(promise.resolve(Ok(value)))
}

/// A step that succeeds with `Nil`. Useful to end a chain of steps.
pub fn done() -> Step(Nil) {
  succeed(Nil)
}

/// A step that immediately fails the test with the given message.
pub fn fail(message: String) -> Step(a) {
  Step(promise.resolve(Error(error.Failed(message))))
}

/// Lift a `Result` into a step.
pub fn from_result(result: Result(a, Error)) -> Step(a) {
  Step(promise.resolve(result))
}

/// Wrap a promise of a result as a step.
pub fn from_promise(promise: Promise(Result(a, Error))) -> Step(a) {
  Step(promise)
}

/// Wrap a promise that cannot fail as a step.
pub fn await(promise: Promise(a)) -> Step(a) {
  Step(promise.map(promise, Ok))
}

/// Get the underlying promise of a step.
pub fn to_promise(step: Step(a)) -> Promise(Result(a, Error)) {
  step.promise
}

/// Run a step for every item in a list, one after another, stopping at the
/// first failure.
pub fn each(items: List(a), with run: fn(a) -> Step(b)) -> Step(Nil) {
  case items {
    [] -> done()
    [item, ..rest] -> try(run(item), fn(_) { each(rest, run) })
  }
}

/// Run a step for every item in a list, one after another, collecting the
/// results.
pub fn map_each(items: List(a), with run: fn(a) -> Step(b)) -> Step(List(b)) {
  list.fold(items, succeed([]), fn(acc, item) {
    use values <- try(acc)
    use value <- try(run(item))
    succeed([value, ..values])
  })
  |> map(list.reverse)
}

/// Pause the test for the given number of milliseconds. Prefer `expect`
/// assertions, which wait automatically, over fixed sleeps.
pub fn sleep(milliseconds: Int) -> Step(Nil) {
  await(promise.wait(milliseconds))
}

/// Add context to the error of a failing step, e.g. `"logging in"`.
pub fn context(step: Step(a), description: String) -> Step(a) {
  promise.map(step.promise, fn(result) {
    case result {
      Ok(value) -> Ok(value)
      Error(e) -> Error(add_context(e, description))
    }
  })
  |> Step
}

fn add_context(e: Error, description: String) -> Error {
  let prefix = fn(message) { description <> ": " <> message }
  case e {
    error.AssertionFailed(message) -> error.AssertionFailed(prefix(message))
    error.Timeout(message) -> error.Timeout(prefix(message))
    error.PlaywrightError(message) -> error.PlaywrightError(prefix(message))
    error.Failed(message) -> error.Failed(prefix(message))
    error.Panic(message) -> error.Panic(prefix(message))
  }
}
