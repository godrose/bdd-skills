import { Then, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import type { World } from "./support";

const gapHeadings = (w: World): string[] => w.subject.split("\n").filter((l) => /^### G[0-9]/.test(l));

Then("it does not mention {string} in any letter case", function (this: World, text: string) {
  assert.ok(!this.subject.toLowerCase().includes(text.toLowerCase()), `has: ${text}`);
});

Then("it lists at least {int} gaps", function (this: World, min: number) {
  const n = gapHeadings(this).length;
  assert.ok(n >= min, `${n} gaps, expected at least ${min}`);
});

Then("every gap in it has these parts:", function (this: World, table: DataTable) {
  const gaps = gapHeadings(this).length;
  table.raw().flat().forEach((part) => {
    const n = this.subject.split("\n").filter((l) => l.includes(part)).length;
    assert.strictEqual(n, gaps, `every gap has ${part}`);
  });
});

Then("no two gaps in it share an id", function (this: World) {
  const ids = gapHeadings(this).map((l) => /^### G[0-9]*/.exec(l)![0]);
  const dup = ids.filter((id, i) => ids.indexOf(id) !== i);
  assert.deepStrictEqual(dup, [], "repeated ids: " + dup.join(", "));
});
