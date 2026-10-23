//// Assertions about the page. Assertions on locators and pages retry until
//// they pass or their timeout (5 seconds by default) runs out, so there's no
//// need to wait for the page to settle first.
////
//// ```gleam
//// use _ <- step.try(
////   page.get_by_role(page, role.Heading)
////   |> expect.locator
////   |> expect.to_have_text("Welcome back"),
//// )
//// use _ <- step.try(expect.page(page) |> expect.to_have_url("/dashboard"))
//// page.get_by_text(page, "Loading")
//// |> expect.locator
//// |> expect.not
//// |> expect.to_be_visible
//// ```

import gleam/javascript/promise.{type Promise}
import gleam/string
import gleewright/error.{type Error}
import gleewright/locator.{type Locator}
import gleewright/page.{type Page}
import gleewright/step.{type Step}

/// Something to make assertions about: a `Locator` or a `Page`.
pub opaque type Expectation(subject) {
  Expectation(subject: Arg, negated: Bool, timeout: Int)
}

/// Make assertions about the elements matched by a locator.
pub fn locator(locator: Locator) -> Expectation(Locator) {
  Expectation(to_arg(locator), negated: False, timeout: -1)
}

/// Make assertions about a page.
pub fn page(page: Page) -> Expectation(Page) {
  Expectation(to_arg(page), negated: False, timeout: -1)
}

/// Invert the assertion that follows.
pub fn not(expectation: Expectation(subject)) -> Expectation(subject) {
  Expectation(..expectation, negated: !expectation.negated)
}

/// Retry the assertion for up to the given number of milliseconds instead of
/// the default 5 seconds.
pub fn within(
  expectation: Expectation(subject),
  milliseconds: Int,
) -> Expectation(subject) {
  Expectation(..expectation, timeout: milliseconds)
}

// --- Locator assertions -----------------------------------------------------

/// The element is visible.
pub fn to_be_visible(expectation: Expectation(Locator)) -> Step(Nil) {
  run(expectation, "toBeVisible", [])
}

/// The element is hidden or not in the page.
pub fn to_be_hidden(expectation: Expectation(Locator)) -> Step(Nil) {
  run(expectation, "toBeHidden", [])
}

/// The element is in the page (though possibly not visible).
pub fn to_be_attached(expectation: Expectation(Locator)) -> Step(Nil) {
  run(expectation, "toBeAttached", [])
}

/// The element is enabled.
pub fn to_be_enabled(expectation: Expectation(Locator)) -> Step(Nil) {
  run(expectation, "toBeEnabled", [])
}

/// The element is disabled.
pub fn to_be_disabled(expectation: Expectation(Locator)) -> Step(Nil) {
  run(expectation, "toBeDisabled", [])
}

/// The element is editable.
pub fn to_be_editable(expectation: Expectation(Locator)) -> Step(Nil) {
  run(expectation, "toBeEditable", [])
}

/// The checkbox or radio button is checked.
pub fn to_be_checked(expectation: Expectation(Locator)) -> Step(Nil) {
  run(expectation, "toBeChecked", [])
}

/// The element has focus.
pub fn to_be_focused(expectation: Expectation(Locator)) -> Step(Nil) {
  run(expectation, "toBeFocused", [])
}

/// The element has no text, or the input has no value.
pub fn to_be_empty(expectation: Expectation(Locator)) -> Step(Nil) {
  run(expectation, "toBeEmpty", [])
}

/// The element's text is exactly the given text, ignoring surrounding
/// whitespace.
pub fn to_have_text(
  expectation: Expectation(Locator),
  text: String,
) -> Step(Nil) {
  run(expectation, "toHaveText", [to_arg(text)])
}

/// The element's text matches a JavaScript regular expression.
pub fn to_have_text_matching(
  expectation: Expectation(Locator),
  pattern: String,
) -> Step(Nil) {
  run(expectation, "toHaveText", [regex(pattern)])
}

/// The texts of all the matched elements are exactly the given texts, in
/// order.
pub fn to_have_texts(
  expectation: Expectation(Locator),
  texts: List(String),
) -> Step(Nil) {
  run(expectation, "toHaveText", [to_arg(array(texts))])
}

/// The element's text contains the given text.
pub fn to_contain_text(
  expectation: Expectation(Locator),
  text: String,
) -> Step(Nil) {
  run(expectation, "toContainText", [to_arg(text)])
}

/// The input's value is the given value.
pub fn to_have_value(
  expectation: Expectation(Locator),
  value: String,
) -> Step(Nil) {
  run(expectation, "toHaveValue", [to_arg(value)])
}

/// The locator matches exactly this many elements.
pub fn to_have_count(
  expectation: Expectation(Locator),
  count: Int,
) -> Step(Nil) {
  run(expectation, "toHaveCount", [to_arg(count)])
}

/// The element has an attribute with the given value.
pub fn to_have_attribute(
  expectation: Expectation(Locator),
  name: String,
  value: String,
) -> Step(Nil) {
  run(expectation, "toHaveAttribute", [to_arg(name), to_arg(value)])
}

/// The element has the given CSS class, amongst any others.
pub fn to_have_class(
  expectation: Expectation(Locator),
  class: String,
) -> Step(Nil) {
  run(expectation, "toContainClass", [to_arg(class)])
}

/// The element has the given `id`.
pub fn to_have_id(expectation: Expectation(Locator), id: String) -> Step(Nil) {
  run(expectation, "toHaveId", [to_arg(id)])
}

/// The element has the given accessible name.
pub fn to_have_accessible_name(
  expectation: Expectation(Locator),
  name: String,
) -> Step(Nil) {
  run(expectation, "toHaveAccessibleName", [to_arg(name)])
}

// --- Page assertions --------------------------------------------------------

/// The page's URL is the given URL. Relative URLs are resolved against the
/// `base_url` of the test config.
pub fn to_have_url(expectation: Expectation(Page), url: String) -> Step(Nil) {
  run(expectation, "toHaveURL", [to_arg(url)])
}

/// The page's URL matches a JavaScript regular expression.
pub fn to_have_url_matching(
  expectation: Expectation(Page),
  pattern: String,
) -> Step(Nil) {
  run(expectation, "toHaveURL", [regex(pattern)])
}

/// The page's title is exactly the given title.
pub fn to_have_title(
  expectation: Expectation(Page),
  title: String,
) -> Step(Nil) {
  run(expectation, "toHaveTitle", [to_arg(title)])
}

/// The page's title matches a JavaScript regular expression.
pub fn to_have_title_matching(
  expectation: Expectation(Page),
  pattern: String,
) -> Step(Nil) {
  run(expectation, "toHaveTitle", [regex(pattern)])
}

// --- Value assertions -------------------------------------------------------

/// Two values are equal. Useful for checking values read with the query
/// functions in `gleewright/locator`, which don't retry.
pub fn equal(actual: a, expected: a) -> Step(Nil) {
  case actual == expected {
    True -> step.done()
    False ->
      step.from_result(
        Error(error.AssertionFailed(
          "expected "
          <> string.inspect(expected)
          <> ", got "
          <> string.inspect(actual),
        )),
      )
  }
}

/// A condition holds, failing with the given message if it doesn't.
pub fn true(condition: Bool, message: String) -> Step(Nil) {
  case condition {
    True -> step.done()
    False -> step.from_result(Error(error.AssertionFailed(message)))
  }
}

// --- Internals --------------------------------------------------------------

type Arg

type Array(a)

fn run(
  expectation: Expectation(subject),
  matcher: String,
  args: List(Arg),
) -> Step(Nil) {
  do_assert(
    expectation.subject,
    expectation.negated,
    expectation.timeout,
    matcher,
    args,
  )
  |> step.from_promise
}

@external(javascript, "../gleewright_ffi.mjs", "assert")
fn do_assert(
  subject: Arg,
  negated: Bool,
  timeout: Int,
  matcher: String,
  args: List(Arg),
) -> Promise(Result(Nil, Error))

@external(javascript, "../gleewright_ffi.mjs", "identity")
fn to_arg(value: a) -> Arg

@external(javascript, "../gleewright_ffi.mjs", "regex")
fn regex(pattern: String) -> Arg

@external(javascript, "../gleewright_ffi.mjs", "toArray")
fn array(list: List(a)) -> Array(a)
