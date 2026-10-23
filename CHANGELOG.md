# Changelog

## Unreleased

- The minimum Gleam version is now 1.14, the oldest release that the
  `gleam_stdlib` 1.x dependency supports.
- Failure screenshot file names start with the test's position in the suite,
  e.g. `3-dashboard-lists-recent-orders.png`, so tests whose names share a
  slug no longer overwrite each other's screenshots.
- `get_by_role_exactly_named` with an empty name matches only elements with
  no accessible name, instead of every element with the role.
- Failure screenshots are retried once if Chromium can't capture the page.

## v0.1.0 - 2026-09-26

- Initial release.
- Test runner with `it`, `describe`, `skip` and `only`, a config builder,
  command line flags (`--grep`, `--headed`, `--browser`, `--slow-mo`), and
  screenshots of failing tests.
- `step` for chaining asynchronous test steps.
- `page` and `locator` for navigating, finding elements and acting on them.
- `expect` for auto-retrying assertions on locators and pages.
- `role` with every ARIA role Playwright supports.
