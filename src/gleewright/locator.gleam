//// Locators find elements on a page. They are lazy: creating a locator
//// doesn't touch the page, and every action re-resolves it, waiting for the
//// element to be attached, visible, stable and enabled as needed.
////
//// Create locators from a page with `page.get_by_role`, `page.get_by_text`,
//// ... and narrow them down with the functions in this module.

import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option}
import gleewright/error.{type Error}
import gleewright/role.{type Role}
import gleewright/step.{type Step}

/// A way to find elements on a page. Create one with the `get_by_*`
/// functions in `gleewright/page`.
pub type Locator

// --- Narrowing --------------------------------------------------------------

/// Find elements matching a CSS or XPath selector inside this locator.
@external(javascript, "../gleewright_ffi.mjs", "locator")
pub fn locator(scope: Locator, selector: String) -> Locator

/// Find elements with the given ARIA role inside this locator.
pub fn get_by_role(scope: Locator, role: Role) -> Locator {
  do_get_by_role(scope, role.to_string(role))
}

/// Find elements with the given ARIA role and accessible name inside this
/// locator. The name matches case-insensitively as a substring.
pub fn get_by_role_named(scope: Locator, role: Role, name: String) -> Locator {
  do_get_by_role_named(scope, role.to_string(role), name, False)
}

/// Like `get_by_role_named`, but the accessible name must match exactly. An
/// empty name matches only elements with no accessible name.
pub fn get_by_role_exactly_named(
  scope: Locator,
  role: Role,
  name: String,
) -> Locator {
  do_get_by_role_named(scope, role.to_string(role), name, True)
}

@external(javascript, "../gleewright_ffi.mjs", "getByRole")
fn do_get_by_role(scope: Locator, role: String) -> Locator

@external(javascript, "../gleewright_ffi.mjs", "getByRoleNamed")
fn do_get_by_role_named(
  scope: Locator,
  role: String,
  name: String,
  exact: Bool,
) -> Locator

/// Find elements containing the given text (case-insensitive substring).
pub fn get_by_text(scope: Locator, text: String) -> Locator {
  do_get_by_text(scope, text, False)
}

/// Find elements whose text is exactly the given text.
pub fn get_by_exact_text(scope: Locator, text: String) -> Locator {
  do_get_by_text(scope, text, True)
}

@external(javascript, "../gleewright_ffi.mjs", "getByText")
fn do_get_by_text(scope: Locator, text: String, exact: Bool) -> Locator

/// Find form controls by the text of their `<label>` or `aria-label`.
pub fn get_by_label(scope: Locator, text: String) -> Locator {
  do_get_by_label(scope, text, False)
}

@external(javascript, "../gleewright_ffi.mjs", "getByLabel")
fn do_get_by_label(scope: Locator, text: String, exact: Bool) -> Locator

/// Find inputs by their placeholder text.
pub fn get_by_placeholder(scope: Locator, text: String) -> Locator {
  do_get_by_placeholder(scope, text, False)
}

@external(javascript, "../gleewright_ffi.mjs", "getByPlaceholder")
fn do_get_by_placeholder(scope: Locator, text: String, exact: Bool) -> Locator

/// Find elements by their `data-testid` attribute.
@external(javascript, "../gleewright_ffi.mjs", "getByTestId")
pub fn get_by_test_id(scope: Locator, id: String) -> Locator

/// Find elements by their `title` attribute.
pub fn get_by_title(scope: Locator, text: String) -> Locator {
  do_get_by_title(scope, text, False)
}

@external(javascript, "../gleewright_ffi.mjs", "getByTitle")
fn do_get_by_title(scope: Locator, text: String, exact: Bool) -> Locator

/// Find images by their `alt` text.
pub fn get_by_alt_text(scope: Locator, text: String) -> Locator {
  do_get_by_alt_text(scope, text, False)
}

@external(javascript, "../gleewright_ffi.mjs", "getByAltText")
fn do_get_by_alt_text(scope: Locator, text: String, exact: Bool) -> Locator

/// The first matching element.
@external(javascript, "../gleewright_ffi.mjs", "first")
pub fn first(locator: Locator) -> Locator

/// The last matching element.
@external(javascript, "../gleewright_ffi.mjs", "last")
pub fn last(locator: Locator) -> Locator

/// The matching element at the given zero-based index.
@external(javascript, "../gleewright_ffi.mjs", "nth")
pub fn nth(locator: Locator, index: Int) -> Locator

/// Keep only elements that contain the given text somewhere inside them.
@external(javascript, "../gleewright_ffi.mjs", "filterHasText")
pub fn with_text(locator: Locator, text: String) -> Locator

/// Keep only elements that do not contain the given text.
@external(javascript, "../gleewright_ffi.mjs", "filterHasNotText")
pub fn without_text(locator: Locator, text: String) -> Locator

/// Keep only elements that contain an element matching `inner`. `inner` is
/// resolved relative to each element, so create it from the page.
@external(javascript, "../gleewright_ffi.mjs", "filterHas")
pub fn containing(locator: Locator, inner: Locator) -> Locator

/// Elements matching both locators.
@external(javascript, "../gleewright_ffi.mjs", "and")
pub fn and(locator: Locator, other: Locator) -> Locator

/// Elements matching either locator.
@external(javascript, "../gleewright_ffi.mjs", "or")
pub fn or(locator: Locator, other: Locator) -> Locator

/// A description of the locator, e.g. `getByRole('button')`.
@external(javascript, "../gleewright_ffi.mjs", "describe")
pub fn describe(locator: Locator) -> String

// --- Actions ----------------------------------------------------------------

/// Click the element.
pub fn click(locator: Locator) -> Step(Nil) {
  step.from_promise(do_click(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "click")
fn do_click(locator: Locator) -> Promise(Result(Nil, Error))

/// Double click the element.
pub fn double_click(locator: Locator) -> Step(Nil) {
  step.from_promise(do_double_click(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "dblclick")
fn do_double_click(locator: Locator) -> Promise(Result(Nil, Error))

/// Replace the value of an input or textarea with the given text.
pub fn fill(locator: Locator, text: String) -> Step(Nil) {
  step.from_promise(do_fill(locator, text))
}

@external(javascript, "../gleewright_ffi.mjs", "fill")
fn do_fill(locator: Locator, text: String) -> Promise(Result(Nil, Error))

/// Clear an input or textarea.
pub fn clear(locator: Locator) -> Step(Nil) {
  step.from_promise(do_clear(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "clear")
fn do_clear(locator: Locator) -> Promise(Result(Nil, Error))

/// Type text into the element one key at a time, firing keyboard events for
/// each character. Prefer `fill` unless the page reacts to individual keys.
pub fn type_text(locator: Locator, text: String) -> Step(Nil) {
  step.from_promise(do_type_text(locator, text))
}

@external(javascript, "../gleewright_ffi.mjs", "pressSequentially")
fn do_type_text(locator: Locator, text: String) -> Promise(Result(Nil, Error))

/// Focus the element and press a key or key combination, e.g. `"Enter"` or
/// `"Control+a"`.
pub fn press(locator: Locator, key: String) -> Step(Nil) {
  step.from_promise(do_press(locator, key))
}

@external(javascript, "../gleewright_ffi.mjs", "press")
fn do_press(locator: Locator, key: String) -> Promise(Result(Nil, Error))

/// Check a checkbox or radio button.
pub fn check(locator: Locator) -> Step(Nil) {
  step.from_promise(do_check(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "check")
fn do_check(locator: Locator) -> Promise(Result(Nil, Error))

/// Uncheck a checkbox.
pub fn uncheck(locator: Locator) -> Step(Nil) {
  step.from_promise(do_uncheck(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "uncheck")
fn do_uncheck(locator: Locator) -> Promise(Result(Nil, Error))

/// Hover the mouse over the element.
pub fn hover(locator: Locator) -> Step(Nil) {
  step.from_promise(do_hover(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "hover")
fn do_hover(locator: Locator) -> Promise(Result(Nil, Error))

/// Focus the element.
pub fn focus(locator: Locator) -> Step(Nil) {
  step.from_promise(do_focus(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "focus")
fn do_focus(locator: Locator) -> Promise(Result(Nil, Error))

/// Remove focus from the element.
pub fn blur(locator: Locator) -> Step(Nil) {
  step.from_promise(do_blur(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "blur")
fn do_blur(locator: Locator) -> Promise(Result(Nil, Error))

/// Scroll the element into view.
pub fn scroll_into_view(locator: Locator) -> Step(Nil) {
  step.from_promise(do_scroll_into_view(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "scrollIntoView")
fn do_scroll_into_view(locator: Locator) -> Promise(Result(Nil, Error))

/// Select an option in a `<select>` by its value or label.
pub fn select_option(locator: Locator, value: String) -> Step(Nil) {
  step.from_promise(do_select_option(locator, value))
}

@external(javascript, "../gleewright_ffi.mjs", "selectOption")
fn do_select_option(
  locator: Locator,
  value: String,
) -> Promise(Result(Nil, Error))

/// Set the file of an `<input type="file">`.
pub fn set_input_file(locator: Locator, path: String) -> Step(Nil) {
  step.from_promise(do_set_input_file(locator, path))
}

@external(javascript, "../gleewright_ffi.mjs", "setInputFile")
fn do_set_input_file(
  locator: Locator,
  path: String,
) -> Promise(Result(Nil, Error))

/// The states `wait_for` can wait for.
pub type State {
  /// The element is in the page.
  Attached
  /// The element is not in the page.
  Detached
  /// The element is in the page and visible.
  Visible
  /// The element is not in the page, or is not visible.
  Hidden
}

/// Wait until the element reaches the given state.
pub fn wait_for(locator: Locator, state: State) -> Step(Nil) {
  let state = case state {
    Attached -> "attached"
    Detached -> "detached"
    Visible -> "visible"
    Hidden -> "hidden"
  }
  step.from_promise(do_wait_for(locator, state))
}

@external(javascript, "../gleewright_ffi.mjs", "waitFor")
fn do_wait_for(locator: Locator, state: String) -> Promise(Result(Nil, Error))

// --- Queries ----------------------------------------------------------------
// Queries read the current state of the page without retrying. To check the
// page is in some state, use the functions in `gleewright/expect`, which wait
// for the state to be reached.

/// The `textContent` of the element.
pub fn text_content(locator: Locator) -> Step(Option(String)) {
  step.from_promise(do_text_content(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "textContent")
fn do_text_content(locator: Locator) -> Promise(Result(Option(String), Error))

/// The rendered text of the element.
pub fn inner_text(locator: Locator) -> Step(String) {
  step.from_promise(do_inner_text(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "innerText")
fn do_inner_text(locator: Locator) -> Promise(Result(String, Error))

/// The rendered text of every matching element.
pub fn all_inner_texts(locator: Locator) -> Step(List(String)) {
  step.from_promise(do_all_inner_texts(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "allInnerTexts")
fn do_all_inner_texts(locator: Locator) -> Promise(Result(List(String), Error))

/// The current value of an input, textarea or select.
pub fn input_value(locator: Locator) -> Step(String) {
  step.from_promise(do_input_value(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "inputValue")
fn do_input_value(locator: Locator) -> Promise(Result(String, Error))

/// The value of an attribute of the element.
pub fn attribute(locator: Locator, name: String) -> Step(Option(String)) {
  step.from_promise(do_attribute(locator, name))
}

@external(javascript, "../gleewright_ffi.mjs", "getAttribute")
fn do_attribute(
  locator: Locator,
  name: String,
) -> Promise(Result(Option(String), Error))

/// How many elements currently match.
pub fn count(locator: Locator) -> Step(Int) {
  step.from_promise(do_count(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "count")
fn do_count(locator: Locator) -> Promise(Result(Int, Error))

/// Whether the element is currently visible.
pub fn is_visible(locator: Locator) -> Step(Bool) {
  step.from_promise(do_is_visible(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "isVisible")
fn do_is_visible(locator: Locator) -> Promise(Result(Bool, Error))

/// Whether the checkbox or radio button is currently checked.
pub fn is_checked(locator: Locator) -> Step(Bool) {
  step.from_promise(do_is_checked(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "isChecked")
fn do_is_checked(locator: Locator) -> Promise(Result(Bool, Error))

/// Whether the element is currently enabled.
pub fn is_enabled(locator: Locator) -> Step(Bool) {
  step.from_promise(do_is_enabled(locator))
}

@external(javascript, "../gleewright_ffi.mjs", "isEnabled")
fn do_is_enabled(locator: Locator) -> Promise(Result(Bool, Error))
