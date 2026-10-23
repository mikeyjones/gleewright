//// A browser tab. Every test gets a fresh page in its own isolated context.

import gleam/dynamic.{type Dynamic}
import gleam/javascript/promise.{type Promise}
import gleewright/browser.{type Context}
import gleewright/error.{type Error}
import gleewright/locator.{type Locator}
import gleewright/role.{type Role}
import gleewright/step.{type Step}

/// A browser tab.
pub type Page

/// Open a new page in a context.
pub fn new(context: Context) -> Step(Page) {
  step.from_promise(do_new(context))
}

@external(javascript, "../gleewright_ffi.mjs", "newPage")
fn do_new(context: Context) -> Promise(Result(Page, Error))

// --- Navigation -------------------------------------------------------------

/// Navigate to a URL and wait for it to load. Relative URLs are resolved
/// against the `base_url` of the test config.
pub fn goto(page: Page, url: String) -> Step(Nil) {
  step.from_promise(do_goto(page, url))
}

@external(javascript, "../gleewright_ffi.mjs", "goto")
fn do_goto(page: Page, url: String) -> Promise(Result(Nil, Error))

/// Reload the page.
pub fn reload(page: Page) -> Step(Nil) {
  step.from_promise(do_reload(page))
}

@external(javascript, "../gleewright_ffi.mjs", "reload")
fn do_reload(page: Page) -> Promise(Result(Nil, Error))

/// Go back in the page's history.
pub fn go_back(page: Page) -> Step(Nil) {
  step.from_promise(do_go_back(page))
}

@external(javascript, "../gleewright_ffi.mjs", "goBack")
fn do_go_back(page: Page) -> Promise(Result(Nil, Error))

/// Go forward in the page's history.
pub fn go_forward(page: Page) -> Step(Nil) {
  step.from_promise(do_go_forward(page))
}

@external(javascript, "../gleewright_ffi.mjs", "goForward")
fn do_go_forward(page: Page) -> Promise(Result(Nil, Error))

/// Wait until the page's URL matches, e.g. after submitting a form. Relative
/// URLs are resolved against the `base_url` of the test config.
pub fn wait_for_url(page: Page, url: String) -> Step(Nil) {
  step.from_promise(do_wait_for_url(page, url))
}

@external(javascript, "../gleewright_ffi.mjs", "waitForUrl")
fn do_wait_for_url(page: Page, url: String) -> Promise(Result(Nil, Error))

/// Replace the page's HTML. Handy for testing components in isolation.
pub fn set_content(page: Page, html: String) -> Step(Nil) {
  step.from_promise(do_set_content(page, html))
}

@external(javascript, "../gleewright_ffi.mjs", "setContent")
fn do_set_content(page: Page, html: String) -> Promise(Result(Nil, Error))

// --- Queries ----------------------------------------------------------------

/// The current URL of the page.
@external(javascript, "../gleewright_ffi.mjs", "url")
pub fn url(page: Page) -> String

/// The page's title.
pub fn title(page: Page) -> Step(String) {
  step.from_promise(do_title(page))
}

@external(javascript, "../gleewright_ffi.mjs", "title")
fn do_title(page: Page) -> Promise(Result(String, Error))

/// The page's full HTML.
pub fn content(page: Page) -> Step(String) {
  step.from_promise(do_content(page))
}

@external(javascript, "../gleewright_ffi.mjs", "content")
fn do_content(page: Page) -> Promise(Result(String, Error))

/// Evaluate a JavaScript expression in the page, e.g.
/// `"document.cookie"` or `"() => window.scrollY"`. Decode the result with
/// `gleam/dynamic/decode`.
pub fn evaluate(page: Page, expression: String) -> Step(Dynamic) {
  step.from_promise(do_evaluate(page, expression))
}

@external(javascript, "../gleewright_ffi.mjs", "evaluate")
fn do_evaluate(
  page: Page,
  expression: String,
) -> Promise(Result(Dynamic, Error))

/// Save a screenshot of the viewport as a PNG.
pub fn screenshot(page: Page, path: String) -> Step(Nil) {
  step.from_promise(do_screenshot(page, path, False))
}

/// Save a screenshot of the whole scrollable page as a PNG.
pub fn full_page_screenshot(page: Page, path: String) -> Step(Nil) {
  step.from_promise(do_screenshot(page, path, True))
}

@external(javascript, "../gleewright_ffi.mjs", "screenshot")
fn do_screenshot(
  page: Page,
  path: String,
  full_page: Bool,
) -> Promise(Result(Nil, Error))

// --- Keyboard ---------------------------------------------------------------

/// Press a key or key combination on the focused element, e.g. `"Tab"` or
/// `"Control+Enter"`.
pub fn press(page: Page, key: String) -> Step(Nil) {
  step.from_promise(do_press(page, key))
}

@external(javascript, "../gleewright_ffi.mjs", "keyboardPress")
fn do_press(page: Page, key: String) -> Promise(Result(Nil, Error))

/// Type text into the focused element one key at a time.
pub fn type_text(page: Page, text: String) -> Step(Nil) {
  step.from_promise(do_type_text(page, text))
}

@external(javascript, "../gleewright_ffi.mjs", "keyboardType")
fn do_type_text(page: Page, text: String) -> Promise(Result(Nil, Error))

// --- Locators ---------------------------------------------------------------

/// Find elements matching a CSS or XPath selector. Prefer the `get_by_*`
/// functions, which match how users see the page.
@external(javascript, "../gleewright_ffi.mjs", "locator")
pub fn locator(page: Page, selector: String) -> Locator

/// Find elements with the given ARIA role.
///
/// ```gleam
/// page.get_by_role(page, role.Heading)
/// ```
pub fn get_by_role(page: Page, role: Role) -> Locator {
  do_get_by_role(page, role.to_string(role))
}

/// Find elements with the given ARIA role and accessible name. The name
/// matches case-insensitively as a substring.
///
/// ```gleam
/// page.get_by_role_named(page, role.Button, "Sign in")
/// ```
pub fn get_by_role_named(page: Page, role: Role, name: String) -> Locator {
  do_get_by_role_named(page, role.to_string(role), name, False)
}

/// Like `get_by_role_named`, but the accessible name must match exactly. An
/// empty name matches only elements with no accessible name.
pub fn get_by_role_exactly_named(
  page: Page,
  role: Role,
  name: String,
) -> Locator {
  do_get_by_role_named(page, role.to_string(role), name, True)
}

@external(javascript, "../gleewright_ffi.mjs", "getByRole")
fn do_get_by_role(page: Page, role: String) -> Locator

@external(javascript, "../gleewright_ffi.mjs", "getByRoleNamed")
fn do_get_by_role_named(
  page: Page,
  role: String,
  name: String,
  exact: Bool,
) -> Locator

/// Find elements containing the given text (case-insensitive substring).
pub fn get_by_text(page: Page, text: String) -> Locator {
  do_get_by_text(page, text, False)
}

/// Find elements whose text is exactly the given text.
pub fn get_by_exact_text(page: Page, text: String) -> Locator {
  do_get_by_text(page, text, True)
}

@external(javascript, "../gleewright_ffi.mjs", "getByText")
fn do_get_by_text(page: Page, text: String, exact: Bool) -> Locator

/// Find form controls by the text of their `<label>` or `aria-label`.
pub fn get_by_label(page: Page, text: String) -> Locator {
  do_get_by_label(page, text, False)
}

@external(javascript, "../gleewright_ffi.mjs", "getByLabel")
fn do_get_by_label(page: Page, text: String, exact: Bool) -> Locator

/// Find inputs by their placeholder text.
pub fn get_by_placeholder(page: Page, text: String) -> Locator {
  do_get_by_placeholder(page, text, False)
}

@external(javascript, "../gleewright_ffi.mjs", "getByPlaceholder")
fn do_get_by_placeholder(page: Page, text: String, exact: Bool) -> Locator

/// Find elements by their `data-testid` attribute.
@external(javascript, "../gleewright_ffi.mjs", "getByTestId")
pub fn get_by_test_id(page: Page, id: String) -> Locator

/// Find elements by their `title` attribute.
pub fn get_by_title(page: Page, text: String) -> Locator {
  do_get_by_title(page, text, False)
}

@external(javascript, "../gleewright_ffi.mjs", "getByTitle")
fn do_get_by_title(page: Page, text: String, exact: Bool) -> Locator

/// Find images by their `alt` text.
pub fn get_by_alt_text(page: Page, text: String) -> Locator {
  do_get_by_alt_text(page, text, False)
}

@external(javascript, "../gleewright_ffi.mjs", "getByAltText")
fn do_get_by_alt_text(page: Page, text: String, exact: Bool) -> Locator
