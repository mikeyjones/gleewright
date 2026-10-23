# gleewright

[![Package Version](https://img.shields.io/hexpm/v/gleewright)](https://hex.pm/packages/gleewright)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleewright/)

[Playwright](https://playwright.dev)-powered end-to-end testing for Gleam.

Write tests against a real Chromium, Firefox or WebKit browser with a typed
Gleam API. Gleewright runs them, reports what failed and why, and saves a
screenshot of every failure.

```gleam
gleewright.it("signs in", fn(page) {
  use _ <- step.try(page.goto(page, "/login"))
  use _ <- step.try(page.get_by_label(page, "Email") |> locator.fill("me@example.com"))
  use _ <- step.try(page.get_by_label(page, "Password") |> locator.fill("hunter2"))
  use _ <- step.try(page.get_by_role_named(page, role.Button, "Sign in") |> locator.click)
  expect.page(page) |> expect.to_have_url("/dashboard")
})
```

```
Running 3 tests in chromium

  ✓ login › signs in (412ms)
  ✓ login › rejects a wrong password (388ms)
  ✗ dashboard › lists recent orders (5.1s)

1) dashboard › lists recent orders

    Assertion failed: expect(locator).toHaveCount(expected) failed

    Locator:  getByRole('row')
    Expected: 3
    Received: 0

    Screenshot: build/gleewright/3-dashboard-lists-recent-orders.png

2 passed, 1 failed (6.2s)
```

## Requirements

- Gleam 1.14 or later
- [Node.js](https://nodejs.org) 20 or later. Gleewright targets JavaScript
  on Node only; Erlang, Deno and Bun are not supported.
- npm, or any package manager that can install `@playwright/test`

## Installation

Gleewright provides the Gleam API and test runner. Playwright provides the
browser automation and assertions. Setup has three parts: install `gleewright`
from Hex, install `@playwright/test` from npm, and download a browser.

Gleewright runs suites with `gleam run`. You don't need a
`playwright.config.ts` file or JavaScript test files, and `npx playwright test`
doesn't run Gleewright suites. Configure your suite with `gleewright.config()`.

### Where to put your tests

Gleewright only runs on JavaScript. Where your tests go depends on your app:

- **Your project targets JavaScript** (a Lustre app, for example): add
  Gleewright to the project and put the suite in `test/`.
- **Your project targets Erlang** (a Wisp or Mist server, for example):
  create a separate JavaScript project for the tests, such as an `e2e/`
  directory next to your app. Don't add Gleewright to an Erlang project. Its
  modules only have JavaScript implementations, so `gleam test` would fail
  to build.

  ```sh
  gleam new e2e
  cd e2e
  ```

  Then add these settings to the new project's `gleam.toml` (put `target`
  alongside `name` and `version`, before any table headings):

  ```toml
  target = "javascript"

  [javascript]
  runtime = "node"
  ```

### Setup

Run these commands from the directory containing the test project's
`gleam.toml`. Keep its `package.json` in that same directory.

**1. Add the Gleam package:**

```sh
gleam add --dev gleewright
```

For a separate e2e project with its suite in `src/`, use `gleam add gleewright`
instead.

**2. Add Playwright.** If the project doesn't have a `package.json` yet, run
`npm init -y` first.

```sh
npm install --save-dev @playwright/test@^1.63.0
```

This is the Playwright version range used by Gleewright's own tests. Install
`@playwright/test`, not just `playwright`: Gleewright imports its assertions too.

**3. Download Chromium**, the default browser:

```sh
npx playwright install chromium
```

On Linux or CI, use `npx playwright install --with-deps chromium` to also
install the required system libraries. For Firefox and WebKit, use
`npx playwright install` to download all three browsers, then select one with
`--browser firefox` or `--browser webkit` when running your suite.

Run the browser installation again whenever you upgrade `@playwright/test`.
Each version expects specific browser builds; see
[Playwright's browser installation guide](https://playwright.dev/docs/browsers).

Add `node_modules` to your `.gitignore` if it isn't there already.
Commit `package.json` and `package-lock.json`; fresh checkouts and CI can then
use `npm ci`, followed by the browser installation command.

## Your first test

A suite is a module with a `main` function. In a JavaScript project, put it
under `test/`. Give it a name that doesn't end in `_test`, because
[gleeunit](https://hexdocs.pm/gleeunit/) treats those modules as unit tests.
In a separate e2e project, it can be the project's main module in `src/`.

```gleam
// test/e2e.gleam
import gleewright
import gleewright/expect
import gleewright/page
import gleewright/role
import gleewright/step

pub fn main() {
  gleewright.config()
  |> gleewright.base_url("https://example.com")
  |> gleewright.main(tests(), _)
}

fn tests() -> List(gleewright.Test) {
  [
    gleewright.it("has a heading", fn(page) {
      use _ <- step.try(page.goto(page, "/"))
      page.get_by_role(page, role.Heading)
      |> expect.locator
      |> expect.to_have_text("Example Domain")
    }),
  ]
}
```

Run it:

```sh
gleam run -m e2e   # a suite in test/e2e.gleam
gleam run          # a separate e2e project
```

The process exits with status `0` when every test passes, `1` when any test
fails or the browser can't start, and `2` for an unknown command line flag.
That makes it easy to use in scripts and CI.

### Testing your own app

Gleewright doesn't start your web server. Start the server first, then point
`base_url` at it:

```sh
gleam run &          # in your app's directory, or however you start your server
gleam run -m e2e     # in the directory that holds the tests
```

In a script or CI, a tool like
[`wait-on`](https://www.npmjs.com/package/wait-on) can wait until the server
is up before the tests start:

```sh
gleam run & npx wait-on http://localhost:3000 && gleam run -m e2e
```

### Command line flags

Flags go after `--`:

| Flag | Effect |
| --- | --- |
| `--grep <text>`, `-g <text>` | Only run tests whose full name contains `<text>` |
| `--headed` | Show the browser window |
| `--browser <name>` | `chromium`, `firefox` or `webkit` |
| `--slow-mo <ms>` | Slow every browser operation down, to watch what happens |

```sh
gleam run -m e2e -- --grep "sign in" --headed --slow-mo 250
```

## Writing tests

### Steps

Browser actions are asynchronous and can fail, so every action returns a
`Step(a)`. Chain steps with `use` and `step.try`. The test returns the last
step, and the first step to fail ends the test:

```gleam
gleewright.it("adds a todo", fn(page) {
  use _ <- step.try(page.goto(page, "/"))
  let input = page.get_by_placeholder(page, "What needs doing?")
  use _ <- step.try(locator.fill(input, "Buy milk"))
  use _ <- step.try(locator.press(input, "Enter"))
  page.get_by_role(page, role.ListItem)
  |> expect.locator
  |> expect.to_have_texts(["Buy milk"])
})
```

Steps that read a value pass it along with `use`:

```gleam
use count <- step.try(page.get_by_role(page, role.ListItem) |> locator.count)
```

### Finding elements

Every test gets a fresh `Page` in its own browser context, so cookies and
storage never leak between tests. Find elements with locators. Prefer
locators that match how people use the page:

```gleam
page.get_by_role_named(page, role.Button, "Save")   // accessible role and name
page.get_by_label(page, "Email")                    // form fields by label
page.get_by_placeholder(page, "Search")
page.get_by_text(page, "Welcome back")
page.get_by_alt_text(page, "Company logo")
page.get_by_test_id(page, "checkout-total")         // data-testid attribute
page.locator(page, "table.orders > tr")             // CSS, as a last resort
```

Narrow a locator down:

```gleam
page.get_by_role(page, role.ListItem)
|> locator.with_text("Buy milk")
|> locator.get_by_role(role.Checkbox)
```

Locators are lazy. Every action waits for its element to be attached,
visible, stable and enabled before it runs, so you rarely need explicit
waits.

### Assertions

`gleewright/expect` assertions keep retrying until they pass or time
out, which is 5 seconds by default:

```gleam
expect.locator(banner) |> expect.to_be_visible
expect.locator(input) |> expect.to_have_value("hello")
expect.locator(rows) |> expect.to_have_count(3)
expect.locator(spinner) |> expect.not |> expect.to_be_visible
expect.locator(report) |> expect.within(30_000) |> expect.to_contain_text("Done")
expect.page(page) |> expect.to_have_url("/dashboard")
expect.page(page) |> expect.to_have_title_matching("^Orders")
```

For plain values, use `expect.equal` or `expect.true`. A Gleam `assert`,
`let assert` or `panic` also fails the test, with a clear report.

### Organising tests

```gleam
[
  gleewright.describe("checkout", [
    gleewright.it("applies a discount code", discount_test),
    gleewright.it("rejects an expired card", expired_card_test)
      |> gleewright.skip,
  ]),
  gleewright.it("work in progress", wip_test) |> gleewright.only,
]
```

When any test or group is marked with `only`, every other test is skipped.

There are no `before_each` hooks. Shared setup is an ordinary function that
takes the rest of the test as a callback:

```gleam
fn signed_in(page: Page, next: fn() -> Step(a)) -> Step(a) {
  use _ <- step.try(page.goto(page, "/login"))
  use _ <- step.try(page.get_by_label(page, "Email") |> locator.fill("me@example.com"))
  use _ <- step.try(page.get_by_label(page, "Password") |> locator.fill("hunter2"))
  use _ <- step.try(page.get_by_role_named(page, role.Button, "Sign in") |> locator.click)
  next()
}

gleewright.it("shows recent orders", fn(page) {
  use <- signed_in(page)
  page.get_by_role(page, role.Row) |> expect.locator |> expect.to_have_count(3)
})
```

### Configuration

Start from `gleewright.config()` and change what you need (`browser.Firefox`
comes from `import gleewright/browser`):

```gleam
gleewright.config()
|> gleewright.base_url("http://localhost:3000")
|> gleewright.browser(browser.Firefox)
|> gleewright.viewport(width: 390, height: 844)
|> gleewright.test_timeout(60_000)
|> gleewright.action_timeout(5000)
|> gleewright.screenshot_dir("build/e2e-failures")
```

| Setting | Default |
| --- | --- |
| Browser | Chromium, headless |
| Base URL | none |
| Viewport | 1280 × 720 |
| Test timeout | 30 seconds |
| Action timeout (clicks, navigation, ...) | 10 seconds |
| Assertion timeout | 5 seconds |
| Failure screenshots | `build/gleewright/` |

Command line flags are applied on top of the config.

### Running from code

`gleewright.run` runs the tests and returns a `Report` instead of
exiting. Add `gleewright.quiet` to the config to stop it printing. Use it
to build your own reporter or to run end-to-end tests from gleeunit:

```gleam
pub fn e2e_test() {
  let config = gleewright.config() |> gleewright.quiet
  use report <- promise.map(gleewright.run(tests(), config))
  let assert Ok(report) = report
  assert gleewright.all_passed(report)
}
```

## Continuous integration

A GitHub Actions job that starts your app and runs the suite:

```yaml
jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: "28"
          gleam-version: "1.18.1"
      - uses: actions/setup-node@v4
        with:
          node-version: "24"
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: gleam run &
      - run: npx wait-on http://localhost:3000
      - run: gleam run -m e2e   # or `gleam run` in a separate e2e project
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: e2e-screenshots
          path: build/gleewright/
```

## Troubleshooting

**`This value is not available ... no implementation for the Erlang
target`**: Gleewright was added to a project that targets Erlang. Move the
suite into a separate JavaScript project, as described in
[Where to put your tests](#where-to-put-your-tests).

**`Executable doesn't exist at .../ms-playwright/...`**: the browsers for
your Playwright version aren't installed. Run `npx playwright install`.

**`Cannot find package '@playwright/test'`**: Playwright isn't installed in
your project. Run `npm install --save-dev @playwright/test` in the directory
that contains `gleam.toml`.

**Host system is missing dependencies**: on Linux, run
`npx playwright install --with-deps` to install the system libraries the
browsers need.

**A locator matches more than one element**: actions such as `click`
require exactly one match. Narrow the locator with `get_by_role_named`,
`locator.with_text`, `locator.first` or `locator.nth`.

## Development

```sh
npm install
npx playwright install chromium
gleam test               # gleewright's own tests, run against inline HTML
gleam run -m example_e2e # an example suite against example.com
```

## Licence

Gleewright is licensed under the [Apache License 2.0](LICENSE).

Playwright is a separate project by Microsoft, also under the Apache License 2.0.
Gleewright isn't affiliated with or endorsed by Microsoft.
