import { Then, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import type { World } from "./support";

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
