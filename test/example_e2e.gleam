//// An example end-to-end suite. Run it with:
////
//// ```sh
//// gleam run -m example_e2e
//// gleam run -m example_e2e -- --headed --grep links
//// ```

import gleewright
import gleewright/expect
import gleewright/locator
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
    gleewright.describe("home page", [
      gleewright.it("has a title and heading", fn(page) {
        use _ <- step.try(page.goto(page, "/"))
        use _ <- step.try(
          expect.page(page) |> expect.to_have_title("Example Domain"),
        )
        page.get_by_role(page, role.Heading)
        |> expect.locator
        |> expect.to_have_text("Example Domain")
      }),
      gleewright.it("links to more information", fn(page) {
        use _ <- step.try(page.goto(page, "/"))
        use _ <- step.try(page.get_by_role(page, role.Link) |> locator.click)
        expect.page(page) |> expect.not |> expect.to_have_url("/")
      }),
    ]),
  ]
}
