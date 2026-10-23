import { chromium, firefox, webkit, expect } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { Result$Ok, Result$Error, toList } from "./gleam.mjs";
import { Option$Some, Option$None } from "../gleam_stdlib/gleam/option.mjs";
import {
  Error$AssertionFailed,
  Error$Timeout,
  Error$PlaywrightError,
  Error$Panic,
} from "./gleewright/error.mjs";

// --- Errors -----------------------------------------------------------------

const ANSI = /\u001b\[[0-9;]*m/g;

function toError(error) {
  const message = String(error?.message ?? error)
    .replace(ANSI, "")
    .trimEnd();
  if (error?.gleam_error) return Error$Panic(message);
  if (error?.matcherResult !== undefined) return Error$AssertionFailed(message);
  if (error?.name === "TimeoutError") return Error$Timeout(message);
  return Error$PlaywrightError(message);
}

async function attempt(f) {
  try {
    return Result$Ok(await f());
  } catch (error) {
    return Result$Error(toError(error));
  }
}

const optional = (value) =>
  value === null || value === undefined ? Option$None() : Option$Some(value);

// --- Browser ----------------------------------------------------------------

const browserTypes = { chromium, firefox, webkit };

export function launch(name, headless, slowMo) {
  return attempt(() => browserTypes[name].launch({ headless, slowMo }));
}

export function closeBrowser(browser) {
  return attempt(async () => {
    await browser.close();
  });
}

export function newContext(browser, baseURL, width, height, timeout) {
  return attempt(async () => {
    const options = { viewport: { width, height } };
    if (baseURL !== "") options.baseURL = baseURL;
    const context = await browser.newContext(options);
    context.setDefaultTimeout(timeout);
    return context;
  });
}

export function closeContext(context) {
  return attempt(async () => {
    await context.close();
  });
}

export function newPage(context) {
  return attempt(() => context.newPage());
}

// --- Page -------------------------------------------------------------------

export function goto(page, url) {
  return attempt(async () => {
    await page.goto(url);
  });
}

export function reload(page) {
  return attempt(async () => {
    await page.reload();
  });
}

export function goBack(page) {
  return attempt(async () => {
    await page.goBack();
  });
}

export function goForward(page) {
  return attempt(async () => {
    await page.goForward();
  });
}

export function url(page) {
  return page.url();
}

export function title(page) {
  return attempt(() => page.title());
}

export function content(page) {
  return attempt(() => page.content());
}

export function setContent(page, html) {
  return attempt(async () => {
    await page.setContent(html);
  });
}

export function waitForUrl(page, url) {
  return attempt(async () => {
    await page.waitForURL(url);
  });
}

export function evaluate(page, expression) {
  return attempt(() => page.evaluate(expression));
}

export function screenshot(page, path, fullPage) {
  return attempt(async () => {
    mkdirSync(dirname(path), { recursive: true });
    try {
      await page.screenshot({ path, fullPage });
    } catch {
      // Chromium sometimes can't capture a page that has only just rendered.
      await new Promise((resolve) => setTimeout(resolve, 100));
      await page.screenshot({ path, fullPage });
    }
  });
}

export function keyboardPress(page, key) {
  return attempt(async () => {
    await page.keyboard.press(key);
  });
}

export function keyboardType(page, text) {
  return attempt(async () => {
    await page.keyboard.type(text);
  });
}

// --- Locators ---------------------------------------------------------------
// These work on both pages and locators, as Playwright shares the API.

export function locator(scope, selector) {
  return scope.locator(selector);
}

export function getByRole(scope, role) {
  return scope.getByRole(role);
}

export function getByRoleNamed(scope, role, name, exact) {
  return scope.getByRole(role, { name, exact });
}

export function getByText(scope, text, exact) {
  return scope.getByText(text, { exact });
}

export function getByLabel(scope, text, exact) {
  return scope.getByLabel(text, { exact });
}

export function getByPlaceholder(scope, text, exact) {
  return scope.getByPlaceholder(text, { exact });
}

export function getByTestId(scope, id) {
  return scope.getByTestId(id);
}

export function getByTitle(scope, text, exact) {
  return scope.getByTitle(text, { exact });
}

export function getByAltText(scope, text, exact) {
  return scope.getByAltText(text, { exact });
}

export function first(locator) {
  return locator.first();
}

export function last(locator) {
  return locator.last();
}

export function nth(locator, index) {
  return locator.nth(index);
}

export function filterHasText(locator, text) {
  return locator.filter({ hasText: text });
}

export function filterHasNotText(locator, text) {
  return locator.filter({ hasNotText: text });
}

export function filterHas(locator, inner) {
  return locator.filter({ has: inner });
}

export function and(a, b) {
  return a.and(b);
}

export function or(a, b) {
  return a.or(b);
}

export function describe(locator) {
  return locator.toString();
}

const action =
  (name) =>
  (locator, ...args) =>
    attempt(async () => {
      await locator[name](...args);
    });

export const click = action("click");
export const dblclick = action("dblclick");
export const fill = action("fill");
export const clear = action("clear");
export const press = action("press");
export const pressSequentially = action("pressSequentially");
export const check = action("check");
export const uncheck = action("uncheck");
export const hover = action("hover");
export const focus = action("focus");
export const blur = action("blur");
export const scrollIntoView = action("scrollIntoViewIfNeeded");

export function selectOption(locator, value) {
  return attempt(async () => {
    await locator.selectOption(value);
  });
}

export function setInputFile(locator, path) {
  return attempt(async () => {
    await locator.setInputFiles(path);
  });
}

export function waitFor(locator, state) {
  return attempt(async () => {
    await locator.waitFor({ state });
  });
}

export function textContent(locator) {
  return attempt(async () => optional(await locator.textContent()));
}

export function innerText(locator) {
  return attempt(() => locator.innerText());
}

export function allInnerTexts(locator) {
  return attempt(async () => toList(await locator.allInnerTexts()));
}

export function inputValue(locator) {
  return attempt(() => locator.inputValue());
}

export function getAttribute(locator, name) {
  return attempt(async () => optional(await locator.getAttribute(name)));
}

export function count(locator) {
  return attempt(() => locator.count());
}

export function isVisible(locator) {
  return attempt(() => locator.isVisible());
}

export function isChecked(locator) {
  return attempt(() => locator.isChecked());
}

export function isEnabled(locator) {
  return attempt(() => locator.isEnabled());
}

// --- Assertions -------------------------------------------------------------

export function assert(target, negated, timeout, matcher, args) {
  return attempt(async () => {
    let assertion = expect(target);
    if (negated) assertion = assertion.not;
    const options = timeout < 0 ? {} : { timeout };
    await assertion[matcher](...args.toArray(), options);
  });
}

export function regex(pattern) {
  return new RegExp(pattern);
}

export function identity(value) {
  return value;
}

export function toArray(list) {
  return list.toArray();
}

// --- Runner -----------------------------------------------------------------

export async function runWithTimeout(thunk, timeout) {
  let timer;
  const timedOut = new Promise((resolve) => {
    timer = setTimeout(
      () => resolve(Result$Error(Error$Timeout(`Test timed out after ${timeout}ms`))),
      timeout,
    );
  });
  const run = (async () => thunk())().catch((error) => Result$Error(toError(error)));
  try {
    return await Promise.race([run, timedOut]);
  } finally {
    clearTimeout(timer);
  }
}

export function now() {
  return Math.round(performance.now());
}

export function argv() {
  return toList(process.argv.slice(2));
}

export function isTty() {
  return Boolean(process.stdout.isTTY) && !process.env.NO_COLOR;
}

export function exit(code) {
  process.exit(code);
}
