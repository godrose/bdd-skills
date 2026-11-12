// Steps for fixture d, the CSV export of issue 41, run through the same flow harness as fixture c.
import { Given, When } from "@cucumber/cucumber";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { type World } from "./support";
import { FLOWS, flow } from "./flow-support";

const CSV_PROJECT = path.join(FLOWS, "fixtures/d/project");

Given("the harness runs deliver on fixture {string} and story {string}", function (this: World, fixture: string, story: string) {
  const f = flow(this);
  f.command = "deliver";
  f.fixture = fixture;
  f.story = story;
});

function dataFile(world: World, rel: string, text: string): void {
  const file = path.join(CSV_PROJECT, rel);
  fs.writeFileSync(file, text + "\n");
  flow(world).fixtureFiles.push(file);
}

Given("a records file {string} in the CSV fixture that holds:", function (this: World, rel: string, text: string) { dataFile(this, rel, text); });
Given("a filter file {string} in the CSV fixture that holds:", function (this: World, rel: string, text: string) { dataFile(this, rel, text); });

function exportScript(world: World, args: string[]): void {
  const r = spawnSync("node", ["src/show.js", ...args], { cwd: CSV_PROJECT, encoding: "utf8" });
  world.status = r.status;
  world.output = (r.stdout ?? "") + (r.stderr ?? "");
}

When("the export script of the CSV fixture is run", function (this: World) { exportScript(this, []); });
When("the export script of the CSV fixture is run on {string}", function (this: World, rel: string) { exportScript(this, [rel]); });
When("the export script of the CSV fixture is run on {string} with the filter {string}", function (this: World, rel: string, filter: string) { exportScript(this, [rel, filter]); });
