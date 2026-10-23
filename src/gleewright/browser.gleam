//// Launching browsers and browser contexts.
////
//// You usually don't need this module: the test runner in `gleewright`
//// launches a browser and gives every test a fresh page in its own context.
//// It is useful for scripting Playwright outside of a test run:
////
//// ```gleam
//// use browser <- step.try(browser.launch(browser.Chromium, headless: True, slow_mo: 0))
//// use context <- step.try(browser.new_context(
////   browser,
////   base_url: "",
////   viewport_width: 1280,
////   viewport_height: 720,
////   timeout: 10_000,
//// ))
//// use page <- step.try(page.new(context))
//// use _ <- step.try(page.goto(page, "https://example.com"))
//// use _ <- step.try(page.screenshot(page, "example.png"))
//// browser.close(browser)
//// ```

import gleam/javascript/promise.{type Promise}
import gleewright/error.{type Error}
import gleewright/step.{type Step}

/// A running browser instance.
pub type Browser

/// An isolated browser session, with its own cookies and storage.
pub type Context

/// Which browser engine to run tests in.
pub type BrowserType {
  /// Chromium, the open source base of Chrome and Edge.
  Chromium
  /// Firefox.
  Firefox
  /// WebKit, the engine behind Safari.
  Webkit
}

/// The name Playwright uses for a browser type, e.g. `"chromium"`.
pub fn browser_type_to_string(browser_type: BrowserType) -> String {
  case browser_type {
    Chromium -> "chromium"
    Firefox -> "firefox"
    Webkit -> "webkit"
  }
}

/// Parse a browser name. Accepts `"chromium"`, `"chrome"`, `"firefox"`,
/// `"webkit"` and `"safari"`.
pub fn browser_type_from_string(name: String) -> Result(BrowserType, Nil) {
  case name {
    "chromium" | "chrome" -> Ok(Chromium)
    "firefox" -> Ok(Firefox)
    "webkit" | "safari" -> Ok(Webkit)
    _ -> Error(Nil)
  }
}

/// Launch a browser.
pub fn launch(
  browser_type: BrowserType,
  headless headless: Bool,
  slow_mo slow_mo: Int,
) -> Step(Browser) {
  do_launch(browser_type_to_string(browser_type), headless, slow_mo)
  |> step.from_promise
}

@external(javascript, "../gleewright_ffi.mjs", "launch")
fn do_launch(
  name: String,
  headless: Bool,
  slow_mo: Int,
) -> Promise(Result(Browser, Error))

/// Close a browser and all of its pages.
pub fn close(browser: Browser) -> Step(Nil) {
  step.from_promise(do_close(browser))
}

@external(javascript, "../gleewright_ffi.mjs", "closeBrowser")
fn do_close(browser: Browser) -> Promise(Result(Nil, Error))

/// Create a new isolated context. Relative URLs passed to `page.goto` are
/// resolved against `base_url`; pass `""` for no base URL. `timeout` is the
/// default timeout in milliseconds for actions and navigations.
pub fn new_context(
  browser: Browser,
  base_url base_url: String,
  viewport_width width: Int,
  viewport_height height: Int,
  timeout timeout: Int,
) -> Step(Context) {
  step.from_promise(do_new_context(browser, base_url, width, height, timeout))
}

@external(javascript, "../gleewright_ffi.mjs", "newContext")
fn do_new_context(
  browser: Browser,
  base_url: String,
  width: Int,
  height: Int,
  timeout: Int,
) -> Promise(Result(Context, Error))

/// Close a context and all of its pages.
pub fn close_context(context: Context) -> Step(Nil) {
  step.from_promise(do_close_context(context))
}

@external(javascript, "../gleewright_ffi.mjs", "closeContext")
fn do_close_context(context: Context) -> Promise(Result(Nil, Error))
