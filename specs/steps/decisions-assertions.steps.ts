import { Then, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import fs from "node:fs";
import type { World } from "./support";
import { fingerprintOf, git, logPath, runScript, section } from "./decisions-support";

Then("the script exits with status {int}", function (this: World, status: number) { assert.strictEqual(this.status, status, this.output); });
Then("the output has {int} lines mentioning {string}", function (this: World, count: number, text: string) {
  assert.strictEqual(this.output.split("\n").filter((l) => l.includes(text)).length, count, this.output);
});
Then("the output is exactly {string}", function (this: World, text: string) { assert.strictEqual(this.output, text); });
Then("the output is {int} characters long", function (this: World, length: number) { assert.strictEqual(this.output.length, length, this.output); });
Then("the output is the remembered fingerprint", function (this: World) { assert.strictEqual(this.output, this.kept); });
Then("the output is not the remembered fingerprint", function (this: World) { assert.notStrictEqual(this.output, this.kept); });
Then("the fingerprint of {string} can be found", function (this: World, id: string) { assert.strictEqual(runScript(this.dir, ["fingerprint", id, "--features", "features"]).status, 0); });

Then("the output lists these in order:", function (this: World, table: DataTable) {
  const lines = this.output.split("\n");
  const at = table.raw().map((r) => lines.findIndex((l) => l.includes(r[0])));
  assert.ok(at.every((n, i) => n >= 0 && (i === 0 || n > at[i - 1])), `order ${at.join(", ")} in: ${this.output}`);
});
Then("the section {string} mentions {string}", function (this: World, heading: string, text: string) {
  assert.ok(section(this.output, heading).includes(text), this.output);
});
Then("the section {string} does not mention {string}", function (this: World, heading: string, text: string) {
  assert.ok(!section(this.output, heading).includes(text), this.output);
});
Then("the output above {string} does not mention {string}", function (this: World, heading: string, text: string) {
  const lines = this.output.split("\n");
  const upTo = lines.findIndex((l) => l.includes(heading));
  assert.ok(upTo >= 0, this.output);
  assert.ok(!lines.slice(0, upTo + 1).join("\n").includes(text), this.output);
});
Then("the output does not mention the fingerprint of {string}", function (this: World, id: string) {
  assert.ok(!this.output.includes(fingerprintOf(this, id)), this.output);
});
Then("the output mentions {string} and the short id of the last commit", function (this: World, text: string) {
  assert.ok(this.output.includes(`${text} ${git(this, "rev-parse", "--short", "HEAD")}`), this.output);
});
Then("showing it again gives the same output", function (this: World) {
  assert.ok(this.run, "nothing was run");
  const again = runScript(this.dir, this.run.args, this.run.env);
  assert.strictEqual(again.output, this.output);
});

Then("the merge has no conflict", function (this: World) { assert.strictEqual(this.status, 0); });
Then("the log {string} has {int} lines", function (this: World, name: string, count: number) {
  assert.strictEqual(fs.readFileSync(logPath(this, name), "utf8").split("\n").length - 1, count);
});
