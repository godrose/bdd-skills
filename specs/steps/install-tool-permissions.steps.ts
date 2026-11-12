import { Given, Then } from "@cucumber/cucumber";
import assert from "node:assert";
import type { World } from "./support";
import { read } from "./support";
import { readClaude, toolLines } from "./install-support";

const installed = (world: World, command: string): string => readClaude(world, `commands/bdd-${command}.md`);

Then("the installed {word} command allows exactly {string}", function (this: World, command: string, tools: string) {
  const want = `allowed-tools: [${tools.split(", ").map((t) => `"${t}"`).join(", ")}]`;
  assert.strictEqual(toolLines(installed(this, command)).join("\n"), want);
});

Then("the installed {word} command has one allowed-tools line", function (this: World, command: string) {
  assert.strictEqual(toolLines(installed(this, command)).length, 1);
});

Then("the installed {word} command has its allowed-tools line right after its description", function (this: World, command: string) {
  const lines = installed(this, command).split("\n");
  const at = lines.findIndex((l) => l.startsWith("description:"));
  assert.ok(at >= 0, "no description line");
  assert.ok((lines[at + 1] ?? "").startsWith("allowed-tools:"), `line after the description is: ${lines[at + 1]}`);
});

Given("the plugin command {string}", function (this: World, command: string) { this.subject = read(`plugin/commands/${command}.md`); });

Then("it has no allowed-tools line", function (this: World) { assert.strictEqual(toolLines(this.subject).length, 0); });
