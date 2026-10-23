import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleewright.{type Report, Failed, Passed, Skipped, TestResult}
import gleewright/error
import gleewright/expect
import gleewright/locator
import gleewright/page
import gleewright/role
import gleewright/step

pub fn main() -> Nil {
  gleeunit.main()
}

const todo_app =
  "
<title>Todos</title>
<h1>My todos</h1>
<label>New todo <input placeholder='What needs doing?'></label>
<button>Add</button>
<ul></ul>
<p data-testid='count'>0 items</p>
<script>
  const input = document.querySelector('input')
  const list = document.querySelector('ul')
  const add = () => {
    if (!input.value) return
    const item = document.createElement('li')
    item.innerHTML = `<label><input type='checkbox'>${input.value}</label>`
    list.append(item)
    input.value = ''
    // Update the count asynchronously to check assertions wait for it.
    setTimeout(() => {
      document.querySelector('[data-testid=count]').textContent =
        list.children.length + ' items'
    }, 200)
  }
  document.querySelector('button').onclick = add
  input.onkeydown = event => event.key === 'Enter' && add()
</script>
"

fn run(tests: List(gleewright.Test)) -> Promise(Report) {
  run_with(tests, gleewright.config() |> gleewright.no_screenshots)
}

fn run_with(tests: List(gleewright.Test), config: gleewright.Config) {
  let config = config |> gleewright.quiet |> gleewright.action_timeout(1000)
  use report <- promise.map(gleewright.run(tests, config))
  let assert Ok(report) = report
  report
}

fn open_app(page: page.Page, next: fn() -> step.Step(a)) -> step.Step(a) {
  use _ <- step.try(page.set_content(page, todo_app))
  next()
}

pub fn passing_test_test() {
  let tests = [
    gleewright.it("adds todos", fn(page) {
      use <- open_app(page)
      use _ <- step.try(expect.page(page) |> expect.to_have_title("Todos"))
      let input = page.get_by_placeholder(page, "What needs doing?")
      use _ <- step.try(locator.fill(input, "Write tests"))
      use _ <- step.try(
        page.get_by_role_named(page, role.Button, "Add") |> locator.click,
      )
      use _ <- step.try(locator.fill(input, "Ship it"))
      use _ <- step.try(locator.press(input, "Enter"))

      let items = page.get_by_role(page, role.ListItem)
      use _ <- step.try(
        expect.locator(items)
        |> expect.to_have_texts(["Write tests", "Ship it"]),
      )
      use _ <- step.try(
        page.get_by_test_id(page, "count")
        |> expect.locator
        |> expect.to_have_text("2 items"),
      )
      use _ <- step.try(expect.locator(input) |> expect.to_be_empty)

      let checkbox =
        items |> locator.with_text("Ship") |> locator.get_by_role(role.Checkbox)
      use _ <- step.try(locator.check(checkbox))
      use _ <- step.try(expect.locator(checkbox) |> expect.to_be_checked)

      use texts <- step.try(locator.all_inner_texts(items))
      use _ <- step.try(expect.equal(texts, ["Write tests", "Ship it"]))
      use count <- step.try(locator.count(items))
      expect.true(count == 2, "expected two items")
    }),
  ]
  use report <- promise.map(run(tests))
  let assert [TestResult(name: "adds todos", outcome: Passed, ..)] =
    report.results
  assert gleewright.all_passed(report)
}

pub fn failing_assertion_test() {
  let tests = [
    gleewright.it("has the wrong heading", fn(page) {
      use <- open_app(page)
      page.get_by_role(page, role.Heading)
      |> expect.locator
      |> expect.within(300)
      |> expect.to_have_text("Someone else's todos")
    }),
  ]
  use report <- promise.map(run(tests))
  let assert [
    TestResult(outcome: Failed(error.AssertionFailed(message), _), ..),
  ] = report.results
  assert string.contains(message, "Someone else's todos")
  assert !gleewright.all_passed(report)
}

pub fn negated_assertion_test() {
  let tests = [
    gleewright.it("has no items", fn(page) {
      use <- open_app(page)
      page.get_by_role(page, role.ListItem)
      |> expect.locator
      |> expect.not
      |> expect.to_be_visible
    }),
    gleewright.it("fails when negated wrongly", fn(page) {
      use <- open_app(page)
      page.get_by_role(page, role.Heading)
      |> expect.locator
      |> expect.within(300)
      |> expect.not
      |> expect.to_be_visible
    }),
  ]
  use report <- promise.map(run(tests))
  let assert [
    TestResult(outcome: Passed, ..),
    TestResult(outcome: Failed(error.AssertionFailed(_), _), ..),
  ] = report.results
}

pub fn action_timeout_test() {
  let tests = [
    gleewright.it("clicks a missing button", fn(page) {
      use <- open_app(page)
      page.get_by_role_named(page, role.Button, "Delete") |> locator.click
    }),
  ]
  use report <- promise.map(run(tests))
  let assert [TestResult(outcome: Failed(error.Timeout(_), _), ..)] =
    report.results
}

pub fn test_timeout_test() {
  let tests = [
    gleewright.it("takes too long", fn(_page) { step.sleep(2000) }),
  ]
  let config = gleewright.config() |> gleewright.test_timeout(200)
  use report <- promise.map(run_with(tests, config))
  let assert [TestResult(outcome: Failed(error.Timeout(message), _), ..)] =
    report.results
  assert message == "Test timed out after 200ms"
}

pub fn step_fail_and_panic_test() {
  let tests = [
    gleewright.it("fails", fn(_page) { step.fail("nope") }),
    gleewright.it("panics", fn(_page) { panic as "oh no" }),
    gleewright.it("panics later", fn(page) {
      use title <- step.try(page.title(page))
      assert title == "something else"
      step.done()
    }),
  ]
  use report <- promise.map(run(tests))
  let assert [
    TestResult(outcome: Failed(error.Failed("nope"), _), ..),
    TestResult(outcome: Failed(error.Panic("oh no"), _), ..),
    TestResult(outcome: Failed(error.Panic(_), _), ..),
  ] = report.results
}

pub fn describe_skip_and_only_test() {
  let pass = fn(_page) { step.done() }
  let tests = [
    gleewright.describe("group", [
      gleewright.it("a", pass),
      gleewright.it("b", pass) |> gleewright.skip,
    ]),
    gleewright.describe("skipped group", [gleewright.it("c", pass)])
      |> gleewright.skip,
  ]
  use report <- promise.await(run(tests))
  let assert [
    TestResult(name: "group › a", outcome: Passed, ..),
    TestResult(name: "group › b", outcome: Skipped, ..),
    TestResult(name: "skipped group › c", outcome: Skipped, ..),
  ] = report.results

  let tests = [
    gleewright.it("a", pass),
    gleewright.describe("focused", [gleewright.it("b", pass)])
      |> gleewright.only,
  ]
  use report <- promise.map(run(tests))
  let assert [
    TestResult(name: "a", outcome: Skipped, ..),
    TestResult(name: "focused › b", outcome: Passed, ..),
  ] = report.results
}

pub fn filter_test() {
  let pass = fn(_page) { step.done() }
  let tests = [
    gleewright.it("logs in", pass),
    gleewright.it("logs out", pass),
    gleewright.it("signs up", pass),
  ]
  let config = gleewright.config() |> gleewright.filter("logs")
  use report <- promise.map(run_with(tests, config))
  assert list.map(report.results, fn(result) { result.name })
    == ["logs in", "logs out"]
}

pub fn with_flags_test() {
  let assert Ok(_) =
    gleewright.config()
    |> gleewright.with_flags([
      "--headed",
      "--grep",
      "x",
      "--browser",
      "firefox",
    ])
  let assert Error("Unknown browser: netscape") =
    gleewright.config()
    |> gleewright.with_flags(["--browser", "netscape"])
  let assert Error("Unknown flag: --nope") =
    gleewright.config() |> gleewright.with_flags(["--nope"])
}

pub fn screenshot_on_failure_test() {
  let tests = [
    gleewright.it("Fails / with a screenshot!", fn(page) {
      use <- open_app(page)
      step.fail("look at the screenshot")
    }),
  ]
  let config = gleewright.config() |> gleewright.screenshot_dir("build/test")
  use report <- promise.map(run_with(tests, config))
  let assert [TestResult(outcome: Failed(_, Some(path)), ..)] = report.results
  assert path == "build/test/1-fails-with-a-screenshot.png"
}

pub fn screenshot_names_are_unique_test() {
  let fail = fn(page) {
    use <- open_app(page)
    step.fail("look at the screenshot")
  }
  let tests = [gleewright.it("A/B", fail), gleewright.it("A B", fail)]
  let config = gleewright.config() |> gleewright.screenshot_dir("build/test")
  use report <- promise.map(run_with(tests, config))
  let assert [
    TestResult(outcome: Failed(_, Some(first)), ..),
    TestResult(outcome: Failed(_, Some(second)), ..),
  ] = report.results
  assert first == "build/test/1-a-b.png"
  assert second == "build/test/2-a-b.png"
}

pub fn empty_accessible_name_test() {
  let tests = [
    gleewright.it("matches only the unnamed button", fn(page) {
      use _ <- step.try(page.set_content(
        page,
        "<div><button>Save</button><button></button></div>",
      ))
      use _ <- step.try(
        page.get_by_role_exactly_named(page, role.Button, "")
        |> expect.locator
        |> expect.to_have_count(1),
      )
      page.locator(page, "div")
      |> locator.get_by_role_exactly_named(role.Button, "")
      |> expect.locator
      |> expect.to_have_count(1)
    }),
  ]
  use report <- promise.map(run(tests))
  let assert [TestResult(outcome: Passed, ..)] = report.results
}

pub fn queries_test() {
  let tests = [
    gleewright.it("reads the page", fn(page) {
      use <- open_app(page)
      let input = page.get_by_label(page, "New todo")
      use _ <- step.try(locator.fill(input, "hello"))
      use value <- step.try(locator.input_value(input))
      use placeholder <- step.try(locator.attribute(input, "placeholder"))
      use missing <- step.try(locator.attribute(input, "nope"))
      use visible <- step.try(locator.is_visible(input))
      use sum <- step.try(page.evaluate(page, "1 + 2"))
      use _ <- step.try(expect.equal(value, "hello"))
      use _ <- step.try(expect.equal(placeholder, Some("What needs doing?")))
      use _ <- step.try(expect.equal(missing, None))
      use _ <- step.try(expect.equal(visible, True))
      expect.equal(string.inspect(sum), "3")
    }),
    gleewright.it("reports failed equality", fn(page) {
      use <- open_app(page)
      use heading <- step.try(
        page.get_by_role(page, role.Heading) |> locator.inner_text,
      )
      expect.equal(heading, "Nope")
    }),
  ]
  use report <- promise.map(run(tests))
  let assert [
    TestResult(outcome: Passed, ..),
    TestResult(outcome: Failed(error.AssertionFailed(message), None), ..),
  ] = report.results
  assert message == "expected \"Nope\", got \"My todos\""
}
