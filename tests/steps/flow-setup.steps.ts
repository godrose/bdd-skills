import { After, Given, When } from "@cucumber/cucumber";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { ROOT, type World } from "./support";
import { FIXTURE_PROJECT, FLOWS, MESSAGES, TEST_OUTPUT, cacheDir, flow, npmLog, play } from "./flow-support";

After(function (this: World) {
  if (this.flow) fs.rmSync(this.flow.tmp, { recursive: true, force: true });
  for (const f of this.flow?.fixtureFiles ?? []) fs.rmSync(f, { force: true });
});

Given("the assistant says the checklist and then the scenarios", function (this: World) {
  flow(this).messages.push(MESSAGES.checklist, MESSAGES.scenarios);
});
Given("the assistant asks for approval once more", function (this: World) { flow(this).messages.push(MESSAGES.extraAsk); });
Given("the assistant ends with the clean report", function (this: World) { flow(this).messages.push(MESSAGES.cleanReport); });
Given("the assistant ends with the parked report", function (this: World) { flow(this).messages.push(MESSAGES.parkedReport); });
Given("the assistant ends with:", function (this: World, text: string) { flow(this).messages.push(text); });

Given("the assistant writes {string} while it says message {int}", function (this: World, file: string, at: number) {
  flow(this).write = { file, at };
});
Given("the product manager replies to message {int} with {string}", function (this: World, n: number, text: string) {
  flow(this).replies.set(n, text);
});

Given("the test run has one pending scenario", function (this: World) { flow(this).testOutput = TEST_OUTPUT.pending; });
Given("the test run has no scenario", function (this: World) { flow(this).testOutput = TEST_OUTPUT.none; });

Given("an empty cache for the installed runner", function (this: World) {
  const f = flow(this);
  fs.rmSync(cacheDir(f), { recursive: true, force: true });
  fs.writeFileSync(npmLog(f), "");
});
Given("the install of the runner fails", function (this: World) { flow(this).installFails = true; });
Given("the conversation has been played once", function (this: World) { play(this); });

// A copy of the harness outside the repo, so that its lockfile can change.
Given("the lockfile of the fixture is changed in a copy of the harness", function (this: World) {
  const f = flow(this);
  const copy = path.join(f.tmp, "lk/flows");
  fs.cpSync(FLOWS, copy, { recursive: true, filter: (src) => !src.startsWith(path.join(FLOWS, "results")) });
  fs.appendFileSync(path.join(copy, "fixtures/c/project/package-lock.json"), '{"x":1}\n');
  f.harness = path.join(copy, "run.sh");
});

Given("a loans file {string} in the fixture that holds:", function (this: World, rel: string, text: string) {
  const file = path.join(FIXTURE_PROJECT, rel);
  fs.writeFileSync(file, text + "\n");
  flow(this).fixtureFiles.push(file);
});

Given("the feature files of the fixture project", function (this: World) {
  const dir = path.join(FIXTURE_PROJECT, "features");
  const lines = fs.readdirSync(dir).filter((n) => n.endsWith(".feature")).flatMap((n) => fs.readFileSync(path.join(dir, n), "utf8").split("\n"));
  flow(this).scenarioCount = lines.filter((l) => /^ *Scenario/.test(l)).length;
});

Given("the workflow files", function (this: World) {
  this.files = fs.readdirSync(path.join(ROOT, ".github/workflows")).filter((n) => n.endsWith(".yml")).map((n) => `.github/workflows/${n}`);
});

Given("a first report that reads:", function (this: World, text: string) { flow(this).reports[0] = text + "\n"; });
Given("a second report that reads:", function (this: World, text: string) { flow(this).reports[1] = text + "\n"; });

When("the harness plays the conversation", function (this: World) { play(this, flow(this).harness); });
When("the harness of the copy plays the conversation", function (this: World) { play(this, flow(this).harness); });

function compare(world: World, second: string): void {
  const f = flow(world);
  const first = path.join(f.tmp, "first.md");
  fs.writeFileSync(first, f.reports[0]);
  const r = spawnSync("bash", [path.join(FLOWS, "run.sh"), "--compare", first, second], { encoding: "utf8" });
  world.status = r.status;
  world.output = (r.stdout ?? "") + (r.stderr ?? "");
}

When("the two reports are compared", function (this: World) {
  const f = flow(this);
  const second = path.join(f.tmp, "second.md");
  fs.writeFileSync(second, f.reports[1]);
  compare(this, second);
});
When("the first report is compared with a report that does not exist", function (this: World) {
  compare(this, path.join(flow(this).tmp, "none.md"));
});

When("the page script of the fixture is run", function (this: World) { showPage(this, []); });
When("the page script of the fixture is run on {string}", function (this: World, rel: string) { showPage(this, [rel]); });

function showPage(world: World, args: string[]): void {
  const r = spawnSync("node", ["src/show.js", ...args], { cwd: FIXTURE_PROJECT, encoding: "utf8" });
  world.status = r.status;
  world.output = (r.stdout ?? "") + (r.stderr ?? "");
}
