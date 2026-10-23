//// Playwright-powered end-to-end testing for Gleam.
////
//// In a Gleam project targeting JavaScript on Node, install both packages
//// and the browser from the directory containing `gleam.toml`:
////
//// ```sh
//// gleam add --dev gleewright
//// npm init -y # only if you don't already have a package.json
//// npm install --save-dev @playwright/test@^1.63.0
//// npx playwright install chromium
//// ```
////
//// For a suite in `src/`, use `gleam add gleewright` without `--dev`.
//// On Linux or CI, `npx playwright install --with-deps chromium` also installs
//// system libraries. Reinstall browsers after upgrading Playwright.
//// Run suites with `gleam run -m <module>`; no `playwright.config.ts` is needed.
//// Gleewright uses its own config and runner, not `npx playwright test`.
////
//// This module defines tests and runs them. The other modules drive the
//// browser:
////
//// - [`step`](gleewright/step.html): chaining asynchronous test steps.
//// - [`page`](gleewright/page.html): navigating and finding elements.
//// - [`locator`](gleewright/locator.html): acting on elements.
//// - [`expect`](gleewright/expect.html): auto-retrying assertions.
//// - [`role`](gleewright/role.html): ARIA roles for `page.get_by_role`.
//// - [`error`](gleewright/error.html): why a test failed.
//// - [`browser`](gleewright/browser.html): driving browsers by hand.
////
//// A suite is a module with a `main` function that calls `main`:
////
//// ```gleam
//// import gleewright
//// import gleewright/expect
//// import gleewright/locator
//// import gleewright/page
//// import gleewright/role
//// import gleewright/step
////
//// pub fn main() {
////   gleewright.config()
////   |> gleewright.base_url("http://localhost:3000")
////   |> gleewright.main(tests(), _)
//// }
////
//// fn tests() -> List(gleewright.Test) {
////   [
////     gleewright.it("signs in", fn(page) {
////       use _ <- step.try(page.goto(page, "/login"))
////       use _ <- step.try(
////         page.get_by_label(page, "Email") |> locator.fill("me@example.com"),
////       )
////       use _ <- step.try(
////         page.get_by_role_named(page, role.Button, "Sign in") |> locator.click,
////       )
////       expect.page(page) |> expect.to_have_url("/dashboard")
////     }),
////   ]
//// }
//// ```
////
//// Run it with `gleam run -m <module>`. See the README for setup.

import gleam/float
import gleam/int
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleewright/browser.{type Browser, type BrowserType}
import gleewright/error.{type Error}
import gleewright/page.{type Page}
import gleewright/step.{type Step}

// --- Tests ------------------------------------------------------------------

/// A test, or a group of tests.
pub opaque type Test {
  Case(name: String, body: fn(Page) -> Step(Nil), mode: Mode)
  Group(name: String, tests: List(Test), mode: Mode)
}

type Mode {
  Normal
  Skip
  Only
}

/// Define a test. The body gets a fresh page in its own browser context, so
/// cookies and storage never leak between tests. The test passes if the step
/// it returns succeeds.
pub fn it(name: String, body: fn(Page) -> Step(Nil)) -> Test {
  Case(name:, body:, mode: Normal)
}

/// Group tests under a common name.
pub fn describe(name: String, tests: List(Test)) -> Test {
  Group(name:, tests:, mode: Normal)
}

/// Skip a test or group.
pub fn skip(t: Test) -> Test {
  set_mode(t, Skip)
}

/// Focus on a test or group: if any test is focused, only focused tests run.
pub fn only(t: Test) -> Test {
  set_mode(t, Only)
}

fn set_mode(t: Test, mode: Mode) -> Test {
  case t {
    Case(..) -> Case(..t, mode:)
    Group(..) -> Group(..t, mode:)
  }
}

// --- Config -----------------------------------------------------------------

/// How to run tests. Create one with `config` and adjust it with the builder
/// functions below.
pub opaque type Config {
  Config(
    browser: BrowserType,
    headless: Bool,
    slow_mo: Int,
    base_url: String,
    test_timeout: Int,
    action_timeout: Int,
    viewport_width: Int,
    viewport_height: Int,
    screenshot_dir: Option(String),
    filter: Option(String),
    quiet: Bool,
  )
}

/// The default config: headless Chromium, a 1280x720 viewport, 30 second
/// test timeout, 10 second action timeout, and screenshots of failing tests
/// saved to `build/gleewright`.
pub fn config() -> Config {
  Config(
    browser: browser.Chromium,
    headless: True,
    slow_mo: 0,
    base_url: "",
    test_timeout: 30_000,
    action_timeout: 10_000,
    viewport_width: 1280,
    viewport_height: 720,
    screenshot_dir: Some("build/gleewright"),
    filter: None,
    quiet: False,
  )
}

/// Which browser to run the tests in.
pub fn browser(config: Config, browser: BrowserType) -> Config {
  Config(..config, browser:)
}

/// Show the browser window while tests run.
pub fn headed(config: Config) -> Config {
  Config(..config, headless: False)
}

/// Slow every Playwright operation down by the given number of
/// milliseconds, to follow along in a headed browser.
pub fn slow_mo(config: Config, milliseconds: Int) -> Config {
  Config(..config, slow_mo: milliseconds)
}

/// The URL relative URLs in `page.goto` and `expect.to_have_url` are
/// resolved against, e.g. `"http://localhost:3000"`.
pub fn base_url(config: Config, url: String) -> Config {
  Config(..config, base_url: url)
}

/// How long a whole test may take, in milliseconds.
pub fn test_timeout(config: Config, milliseconds: Int) -> Config {
  Config(..config, test_timeout: milliseconds)
}

/// How long a single action such as a click or navigation may take, in
/// milliseconds.
pub fn action_timeout(config: Config, milliseconds: Int) -> Config {
  Config(..config, action_timeout: milliseconds)
}

/// The size of the browser viewport.
pub fn viewport(
  config: Config,
  width width: Int,
  height height: Int,
) -> Config {
  Config(..config, viewport_width: width, viewport_height: height)
}

/// Where to save screenshots of failing tests.
pub fn screenshot_dir(config: Config, directory: String) -> Config {
  Config(..config, screenshot_dir: Some(directory))
}

/// Don't take screenshots of failing tests.
pub fn no_screenshots(config: Config) -> Config {
  Config(..config, screenshot_dir: None)
}

/// Only run tests whose full name contains the given text.
pub fn filter(config: Config, text: String) -> Config {
  Config(..config, filter: Some(text))
}

/// Don't print anything while running.
pub fn quiet(config: Config) -> Config {
  Config(..config, quiet: True)
}

/// Apply command line flags to a config:
///
/// - `--grep <text>` only runs tests whose name contains the text
/// - `--headed` shows the browser window
/// - `--browser <chromium|firefox|webkit>` picks the browser
/// - `--slow-mo <ms>` slows every operation down
pub fn with_flags(
  config: Config,
  flags: List(String),
) -> Result(Config, String) {
  case flags {
    [] -> Ok(config)
    ["--headed", ..rest] -> with_flags(headed(config), rest)
    ["--grep", text, ..rest] | ["-g", text, ..rest] ->
      with_flags(filter(config, text), rest)
    ["--browser", name, ..rest] ->
      case browser.browser_type_from_string(name) {
        Ok(browser_type) -> with_flags(browser(config, browser_type), rest)
        Error(_) -> Error("Unknown browser: " <> name)
      }
    ["--slow-mo", milliseconds, ..rest] ->
      case int.parse(milliseconds) {
        Ok(milliseconds) -> with_flags(slow_mo(config, milliseconds), rest)
        Error(_) -> Error("--slow-mo expects a number of milliseconds")
      }
    [flag, ..] -> Error("Unknown flag: " <> flag)
  }
}

// --- Running ----------------------------------------------------------------

/// The outcome of a test run.
pub type Report {
  Report(results: List(TestResult), duration: Int)
}

/// The outcome of a single test. `name` includes the names of the groups the
/// test is in, separated by ` › `.
pub type TestResult {
  TestResult(name: String, outcome: Outcome, duration: Int)
}

/// How a single test ended.
pub type Outcome {
  /// Every step of the test succeeded.
  Passed
  /// A step failed. `screenshot` is the path of a screenshot of the page
  /// taken at the time of the failure, if screenshots are enabled.
  Failed(error: Error, screenshot: Option(String))
  /// The test was skipped with `skip`, or another test was focused with
  /// `only`.
  Skipped
}

/// Whether every test that ran passed.
pub fn all_passed(report: Report) -> Bool {
  list.all(report.results, fn(result) {
    case result.outcome {
      Passed | Skipped -> True
      Failed(..) -> False
    }
  })
}

/// Run tests from a `main` function: reads command line flags (see
/// `with_flags`), runs the tests, prints the results, and exits with a
/// non-zero status if any test failed.
///
/// ```sh
/// gleam run -m my_app_e2e -- --grep login --headed
/// ```
pub fn main(tests: List(Test), config: Config) -> Promise(Nil) {
  case with_flags(config, argv()) {
    Error(message) -> {
      io.println_error(message)
      exit(2)
      promise.resolve(Nil)
    }
    Ok(config) -> {
      use report <- promise.map(run(tests, config))
      case report {
        Ok(report) ->
          case all_passed(report) {
            True -> exit(0)
            False -> exit(1)
          }
        Error(error) -> {
          io.println_error(
            "Could not start the browser.\n\n" <> error.to_string(error),
          )
          exit(1)
        }
      }
    }
  }
}

/// Run tests one after another, each with a fresh page. Fails only if the
/// browser could not be launched; test failures are recorded in the report.
pub fn run(
  tests: List(Test),
  config: Config,
) -> Promise(Result(Report, Error)) {
  let start = now()
  let planned = plan(tests, config.filter)
  let to_run = list.count(planned, fn(entry) { !entry.skipped })
  log(
    config,
    "\nRunning "
      <> pluralise(to_run, "test")
      <> " in "
      <> browser.browser_type_to_string(config.browser)
      <> "\n",
  )

  let launched =
    browser.launch(config.browser, config.headless, config.slow_mo)
    |> step.to_promise
  use launched <- promise.await(launched)
  case launched {
    Error(error) -> promise.resolve(Error(error))
    Ok(browser) -> {
      use results <- promise.await(run_all(browser, config, planned, []))
      use _ <- promise.map(step.to_promise(browser.close(browser)))
      let report = Report(results:, duration: now() - start)
      log(config, summary(report))
      Ok(report)
    }
  }
}

type Planned {
  Planned(
    index: Int,
    name: String,
    body: fn(Page) -> Step(Nil),
    skipped: Bool,
    focused: Bool,
  )
}

fn plan(tests: List(Test), filter: Option(String)) -> List(Planned) {
  let planned =
    flatten(tests, [], skipped: False, focused: False)
    |> list.index_map(fn(entry, index) { Planned(..entry, index: index + 1) })
    |> list.filter(fn(entry) {
      case filter {
        Some(text) -> string.contains(entry.name, text)
        None -> True
      }
    })
  case list.any(planned, fn(entry) { entry.focused }) {
    False -> planned
    True ->
      list.map(planned, fn(entry) {
        Planned(..entry, skipped: entry.skipped || !entry.focused)
      })
  }
}

fn flatten(
  tests: List(Test),
  path: List(String),
  skipped skipped: Bool,
  focused focused: Bool,
) -> List(Planned) {
  list.flat_map(tests, fn(t) {
    let skipped = skipped || t.mode == Skip
    let focused = focused || t.mode == Only
    case t {
      Case(name:, body:, ..) -> {
        let name = string.join(list.reverse([name, ..path]), " › ")
        [Planned(index: 0, name:, body:, skipped:, focused:)]
      }
      Group(name:, tests:, ..) ->
        flatten(tests, [name, ..path], skipped:, focused:)
    }
  })
}

fn run_all(
  browser: Browser,
  config: Config,
  planned: List(Planned),
  acc: List(TestResult),
) -> Promise(List(TestResult)) {
  case planned {
    [] -> promise.resolve(list.reverse(acc))
    [entry, ..rest] -> {
      use result <- promise.await(run_one(browser, config, entry))
      log(config, result_line(result))
      run_all(browser, config, rest, [result, ..acc])
    }
  }
}

fn run_one(
  browser: Browser,
  config: Config,
  entry: Planned,
) -> Promise(TestResult) {
  let start = now()
  let finish = fn(outcome) { TestResult(entry.name, outcome, now() - start) }
  case entry.skipped {
    True -> promise.resolve(TestResult(entry.name, Skipped, 0))
    False -> {
      let context =
        browser.new_context(
          browser,
          base_url: config.base_url,
          viewport_width: config.viewport_width,
          viewport_height: config.viewport_height,
          timeout: config.action_timeout,
        )
      use context <- promise.await(step.to_promise(context))
      case context {
        Error(error) -> promise.resolve(finish(Failed(error, None)))
        Ok(context) -> {
          use outcome <- promise.await(run_body(config, context, entry))
          use _ <- promise.map(step.to_promise(browser.close_context(context)))
          finish(outcome)
        }
      }
    }
  }
}

fn run_body(
  config: Config,
  context: browser.Context,
  entry: Planned,
) -> Promise(Outcome) {
  use page <- promise.await(step.to_promise(page.new(context)))
  case page {
    Error(error) -> promise.resolve(Failed(error, None))
    Ok(page) -> {
      let run = fn() { step.to_promise(entry.body(page)) }
      use result <- promise.await(run_with_timeout(run, config.test_timeout))
      case result, config.screenshot_dir {
        Ok(_), _ -> promise.resolve(Passed)
        Error(error), None -> promise.resolve(Failed(error, None))
        Error(error), Some(directory) -> {
          let path = directory <> "/" <> screenshot_name(entry) <> ".png"
          use screenshot <- promise.map(
            step.to_promise(page.screenshot(page, path)),
          )
          case screenshot {
            Ok(_) -> Failed(error, Some(path))
            Error(_) -> Failed(error, None)
          }
        }
      }
    }
  }
}

/// The test's position in the suite keeps the file name unique when two names
/// share a slug, such as `A/B` and `A B`.
fn screenshot_name(entry: Planned) -> String {
  let index = int.to_string(entry.index)
  case slug(entry.name) {
    "" -> index
    slug -> index <> "-" <> slug
  }
}

fn slug(name: String) -> String {
  name
  |> string.lowercase
  |> string.to_graphemes
  |> list.map(fn(char) {
    case is_alphanumeric(char) {
      True -> char
      False -> "-"
    }
  })
  |> string.concat
  |> string.split("-")
  |> list.filter(fn(part) { part != "" })
  |> string.join("-")
}

fn is_alphanumeric(char: String) -> Bool {
  string.contains("abcdefghijklmnopqrstuvwxyz0123456789", char)
}

// --- Reporting --------------------------------------------------------------

fn log(config: Config, message: String) -> Nil {
  case config.quiet {
    True -> Nil
    False -> io.println(message)
  }
}

fn result_line(result: TestResult) -> String {
  case result.outcome {
    Passed ->
      "  "
      <> green("✓")
      <> " "
      <> result.name
      <> dim(" (" <> format_duration(result.duration) <> ")")
    Failed(..) ->
      "  "
      <> red("✗ " <> result.name)
      <> dim(" (" <> format_duration(result.duration) <> ")")
    Skipped -> "  " <> yellow("- " <> result.name)
  }
}

fn summary(report: Report) -> String {
  let failures =
    list.filter_map(report.results, fn(result) {
      case result.outcome {
        Failed(error:, screenshot:) -> Ok(#(result.name, error, screenshot))
        _ -> Error(Nil)
      }
    })

  let failure_details =
    list.index_map(failures, fn(failure, index) {
      let #(name, error, screenshot) = failure
      let screenshot = case screenshot {
        Some(path) -> "\n\n" <> indent(dim("Screenshot: " <> path))
        None -> ""
      }
      "\n"
      <> red(int.to_string(index + 1) <> ") " <> name)
      <> "\n\n"
      <> indent(error.to_string(error))
      <> screenshot
      <> "\n"
    })
    |> string.concat

  let count = fn(outcome) {
    list.count(report.results, fn(result) { result.outcome == outcome })
  }
  let counts =
    [
      #(count(Passed), "passed", green),
      #(list.length(failures), "failed", red),
      #(count(Skipped), "skipped", yellow),
    ]
    |> list.filter(fn(entry) { entry.0 > 0 })
    |> list.map(fn(entry) {
      let #(count, label, colour) = entry
      colour(int.to_string(count) <> " " <> label)
    })
    |> string.join(", ")
  let counts = case counts {
    "" -> "No tests found"
    _ -> counts
  }

  failure_details
  <> "\n"
  <> counts
  <> dim(" (" <> format_duration(report.duration) <> ")")
}

fn indent(text: String) -> String {
  text
  |> string.split("\n")
  |> list.map(fn(line) {
    case line {
      "" -> ""
      _ -> "    " <> line
    }
  })
  |> string.join("\n")
}

fn format_duration(milliseconds: Int) -> String {
  case milliseconds < 1000 {
    True -> int.to_string(milliseconds) <> "ms"
    False ->
      float.to_string(float.to_precision(
        int.to_float(milliseconds) /. 1000.0,
        1,
      ))
      <> "s"
  }
}

fn pluralise(count: Int, noun: String) -> String {
  case count {
    1 -> "1 " <> noun
    _ -> int.to_string(count) <> " " <> noun <> "s"
  }
}

fn green(text: String) -> String {
  colour(text, "32")
}

fn red(text: String) -> String {
  colour(text, "31")
}

fn yellow(text: String) -> String {
  colour(text, "33")
}

fn dim(text: String) -> String {
  colour(text, "2")
}

fn colour(text: String, code: String) -> String {
  case is_tty() {
    True -> "\u{001b}[" <> code <> "m" <> text <> "\u{001b}[0m"
    False -> text
  }
}

// --- FFI --------------------------------------------------------------------

@external(javascript, "./gleewright_ffi.mjs", "runWithTimeout")
fn run_with_timeout(
  run: fn() -> Promise(Result(Nil, Error)),
  timeout: Int,
) -> Promise(Result(Nil, Error))

@external(javascript, "./gleewright_ffi.mjs", "now")
fn now() -> Int

@external(javascript, "./gleewright_ffi.mjs", "argv")
fn argv() -> List(String)

@external(javascript, "./gleewright_ffi.mjs", "isTty")
fn is_tty() -> Bool

@external(javascript, "./gleewright_ffi.mjs", "exit")
fn exit(code: Int) -> Nil
