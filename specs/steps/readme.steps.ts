import { Given, Then, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { ROOT, read, type World } from "./support";

const EM_DASH = String.fromCharCode(0x2014);
const lines = (w: World): string[] => w.subject.split("\n");
const firstLine = (w: World, text: string): number => lines(w).findIndex((l) => l.includes(text)) + 1;
const lower = (s: string): string => s.replace(/[A-Z]/g, (c) => c.toLowerCase());

const inOrder = (w: World, texts: string[]): void => {
  const at = texts.map((t) => firstLine(w, t));
  const bad = at.some((n, i) => n === 0 || (i > 0 && at[i - 1] >= n));
  assert.ok(!bad, "not in this order: " + texts.map((t, i) => `'${t}' (${at[i] || "missing"})`).join(", "));
};

Then("it mentions these in this order:", function (this: World, table: DataTable) {
  inOrder(this, table.raw().flat());
});

Then("each of these comes before {string}:", function (this: World, later: string, table: DataTable) {
  table.raw().flat().forEach((t) => inOrder(this, [t, later]));
});

Then("it has at least {int} details blocks", function (this: World, min: number) {
  const n = lines(this).filter((l) => l.startsWith("<details>")).length;
  assert.ok(n >= min, `${n} details blocks, expected at least ${min}`);
});

Then("its details blocks open and close in equal number", function (this: World) {
  const count = (tag: string): number => lines(this).filter((l) => l.startsWith(tag)).length;
  assert.strictEqual(count("<details>"), count("</details>"), "unbalanced details blocks");
});

Then("every heading link in it points at a level 2 or 3 heading", function (this: World) {
  const slugs = lines(this)
    .filter((l) => /^#{2,3} /.test(l))
    .map((l) => lower(l).replace(/^#+ /, "").replace(/[^a-z0-9 -]/g, "").replace(/ /g, "-"));
  const links = [...this.subject.matchAll(/\]\(#([a-z0-9-]*)\)/g)].map((m) => m[1]);
  const bad = [...new Set(links)].filter((a) => !slugs.includes(a));
  assert.deepStrictEqual(bad, [], "links with no heading: " + bad.join(", "));
});

Then("it has no heading with a non-ASCII character", function (this: World) {
  const bad = lines(this).filter((l) => /^## .*[^ -~]/.test(l));
  assert.deepStrictEqual(bad, [], "non-ASCII headings: " + bad.join(" | "));
});

Then("it has no em-dash", function (this: World) {
  assert.ok(!this.subject.includes(EM_DASH), "has an em-dash");
});

Then("its last non-empty line is {string}", function (this: World, expected: string) {
  const last = lines(this).filter((l) => l !== "").pop();
  assert.strictEqual(last, expected);
});

const section = (w: World, heading: string): string => {
  const all = lines(w);
  const level = heading.match(/^#+/)![0].length;
  const start = all.findIndex((l) => l === heading);
  assert.ok(start >= 0, `no section '${heading}'`);
  const end = all.findIndex((l, i) => i > start && new RegExp(`^#{1,${level}} `).test(l));
  return all.slice(start + 1, end < 0 ? undefined : end).join("\n");
};

Then("it has a section {string} holding:", function (this: World, heading: string, table: DataTable) {
  const body = section(this, heading);
  const missing = table.raw().flat().filter((t) => !body.includes(t));
  assert.deepStrictEqual(missing, [], `missing from '${heading}': ${missing.join(" | ")}`);
});

Then("every row named in the section {string} is a row of the config template", function (this: World, heading: string) {
  const template = read("plugin/bdd-config.template.md");
  const rows = new Set([...template.matchAll(/^\| (\w+) \|/gm)].map((m) => m[1]));
  const named = [...section(this, heading).matchAll(/^\| `(\w+)` \|/gm)].map((m) => m[1]);
  assert.ok(named.length > 0, `'${heading}' names no rows`);
  const unknown = named.filter((n) => !rows.has(n));
  assert.deepStrictEqual(unknown, [], "not in the template: " + unknown.join(", "));
});

Then("its install line names the marketplace of the marketplace file", function (this: World) {
  const name = JSON.parse(read(".claude-plugin/marketplace.json")).name as string;
  assert.ok(this.subject.includes("/plugin install bdd@" + name), "the install line does not name " + name);
});

Then("every relative link in it points at a file that exists", function (this: World) {
  const links = [...this.subject.matchAll(/\]\((?!https?:|#|mailto:)([^)\s#]+)/g)].map((m) => m[1]);
  assert.ok(links.length > 0, "no relative links found");
  const bad = [...new Set(links)].filter((l) => !fs.existsSync(path.join(ROOT, l)));
  assert.deepStrictEqual(bad, [], "links to files that do not exist: " + bad.join(", "));
});

Given("the tracked text files of the repo", function (this: World) {
  const names = execFileSync("git", ["ls-files"], { cwd: ROOT, encoding: "utf8" }).split("\n").filter(Boolean);
  this.files = names.filter((n) => /\.(md|ts|json|yml|yaml|sh|feature|txt|js)$/.test(n) && !n.endsWith("package-lock.json"));
});

Then("none of them names the trial project", function (this: World) {
  const word = ["bdd", "net" + "core"].join("-");
  const bad = this.files.filter((n) => n.toLowerCase().includes(word) || read(n).toLowerCase().includes(word));
  assert.deepStrictEqual(bad, [], "names the trial project: " + bad.join(", "));
});
