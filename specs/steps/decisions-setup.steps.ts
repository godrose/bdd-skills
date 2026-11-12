import { Given, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import fs from "node:fs";
import path from "node:path";
import type { World } from "./support";
import { HEADER_ROW_FEATURE, appendLines, commitAll, decisionLines, editFeature, featurePath, fingerprintOf, git, logPath, newProject } from "./decisions-support";

Given("a project with the header row scenario", function (this: World) {
  newProject(this);
  fs.writeFileSync(featurePath(this, "export.feature"), HEADER_ROW_FEATURE);
});
Given("a project with no scenarios", function (this: World) { newProject(this); });
Given("the decisions folder is missing", function (this: World) { fs.rmSync(path.join(this.dir, "docs/decisions"), { recursive: true, force: true }); });
Given("the features folder is missing", function (this: World) { fs.rmSync(path.join(this.dir, "features"), { recursive: true, force: true }); });

function writeFeature(world: World, rel: string, text: string): void {
  if (!world.dir) newProject(world);
  fs.mkdirSync(path.dirname(featurePath(world, rel)), { recursive: true });
  fs.writeFileSync(featurePath(world, rel), text);
}
Given("the feature file {string} reads:", function (this: World, rel: string, text: string) { writeFeature(this, rel, text + "\n"); });
Given("the feature file {string} reads, with Windows line endings:", function (this: World, rel: string, text: string) { writeFeature(this, rel, text.split("\n").join("\r\n") + "\r\n"); });
Given("the feature file {string} reads, with no final newline:", function (this: World, rel: string, text: string) { writeFeature(this, rel, text); });
Given("the feature file {string} is copied to {string}", function (this: World, from: string, to: string) { fs.copyFileSync(featurePath(this, from), featurePath(this, to)); });
Given("the feature file {string} is deleted", function (this: World, rel: string) { fs.rmSync(featurePath(this, rel)); });
Given("the text {string} is replaced by {string} in the feature file {string}", function (this: World, from: string, to: string, rel: string) {
  editFeature(this, rel, (text) => {
    assert.ok(text.includes(from), `no "${from}" in ${rel}`);
    return text.split(from).join(to);
  });
});

Given("the log {string} gets these decisions:", function (this: World, name: string, table: DataTable) { appendLines(this, name, decisionLines(this, table)); });
Given("the log {string} in the folder {string} gets these decisions:", function (this: World, name: string, folder: string, table: DataTable) { appendLines(this, name, decisionLines(this, table), folder); });
Given("the log {string} gets these lines:", function (this: World, name: string, text: string) { appendLines(this, name, text.split("\n")); });
Given("the log {string} gets the open question {string} dated {string}: {string}", function (this: World, name: string, id: string, at: string, text: string) {
  appendLines(this, name, [JSON.stringify({ v: 1, id, kind: "open", story: id.slice(0, id.lastIndexOf("-")), at, text })]);
});
Given("the decision {string} in the log {string} has the source of kind {string} with the reference {string} and the role {string}", function (this: World, id: string, name: string, kind: string, ref: string, role: string) {
  const lines = fs.readFileSync(logPath(this, name), "utf8").split("\n").filter((l) => l !== "").map((l) => {
    const rec = JSON.parse(l);
    if (rec.id === id) rec.sources = [{ kind, ref, role }];
    return JSON.stringify(rec);
  });
  fs.writeFileSync(logPath(this, name), lines.map((l) => l + "\n").join(""));
});
Given("the log {string} is written with Windows line endings, a blank line between the records and no final newline, holding these decisions:", function (this: World, name: string, table: DataTable) {
  fs.writeFileSync(logPath(this, name), decisionLines(this, table).join("\r\n\r\n"));
});
Given("the log {string} is empty", function (this: World, name: string) { fs.writeFileSync(logPath(this, name), ""); });
Given("the log {string} is emptied", function (this: World, name: string) { fs.writeFileSync(logPath(this, name), ""); });
Given("the log {string} is deleted", function (this: World, name: string) { fs.rmSync(logPath(this, name)); });
Given("the first line of the log {string} is deleted", function (this: World, name: string) {
  const lines = fs.readFileSync(logPath(this, name), "utf8").split("\n");
  fs.writeFileSync(logPath(this, name), lines.slice(1).join("\n"));
});
Given("the word {string} is changed to {string} in the log {string}", function (this: World, from: string, to: string, name: string) {
  const text = fs.readFileSync(logPath(this, name), "utf8");
  assert.ok(text.includes(from), `no "${from}" in the log`);
  fs.writeFileSync(logPath(this, name), text.replace(from, to));
});
Given("the log {string} is rewritten with Windows line endings", function (this: World, name: string) {
  fs.writeFileSync(logPath(this, name), fs.readFileSync(logPath(this, name), "utf8").replace(/\r?\n/g, "\r\n"));
});
Given("the log {string} is rewritten with Unix line endings", function (this: World, name: string) {
  fs.writeFileSync(logPath(this, name), fs.readFileSync(logPath(this, name), "utf8").replace(/\r\n/g, "\n"));
});

Given("the project is committed", function (this: World) { commitAll(this, "base"); });
Given("the git attributes merge the log files by union", function (this: World) {
  fs.writeFileSync(path.join(this.dir, ".gitattributes"), "docs/decisions/*.jsonl merge=union\n");
  commitAll(this, "attrs");
});
Given("a branch {string} cut from the main branch where the log {string} gets these decisions:", function (this: World, branch: string, name: string, table: DataTable) {
  git(this, "checkout", "-q", "-b", branch, "main");
  appendLines(this, name, decisionLines(this, table));
  git(this, "commit", "-q", "-am", branch);
  git(this, "checkout", "-q", "main");
});

Given("the fingerprint of {string} is remembered", function (this: World, id: string) { this.kept = fingerprintOf(this, id); });
