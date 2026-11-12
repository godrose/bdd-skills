import { Given, Then, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import fs from "node:fs";
import path from "node:path";
import { ROOT, read, type World } from "./support";

const EM_DASH = String.fromCharCode(0x2014);
const abs = (rel: string): string => path.join(ROOT, rel);

const valueAt = (w: World, key: string): unknown =>
  key.split(".").reduce<unknown>((node, part) => (node as Record<string, unknown> | undefined)?.[part], JSON.parse(w.subject));
const manifestVersion = (): string => JSON.parse(read("plugin/.claude-plugin/plugin.json")).version;

Given("the plugin manifest", function (this: World) { this.subject = read("plugin/.claude-plugin/plugin.json"); });

Then("its {string} is {string}", function (this: World, key: string, expected: string) {
  assert.strictEqual(valueAt(this, key), expected, key);
});

Then("its {string} is not empty", function (this: World, key: string) {
  const value = valueAt(this, key);
  assert.ok(typeof value === "string" && value !== "", `${key} is empty or missing`);
});

Then("its {string} is a semantic version", function (this: World, key: string) {
  const value = valueAt(this, key);
  assert.ok(typeof value === "string" && /^[0-9]+\.[0-9]+\.[0-9]+$/.test(value), `${key} is not semver: ${String(value)}`);
});

Then("its {string} is the version of the plugin manifest", function (this: World, key: string) {
  assert.strictEqual(valueAt(this, key), manifestVersion(), key);
});

Then("it has an entry for the version of the plugin manifest", function (this: World) {
  const heading = `## ${manifestVersion()}`;
  assert.ok(this.subject.includes(heading), `lacks: ${heading}`);
});

Given("the commands, agents and config template of the plugin", function (this: World) {
  const list = (dir: string): string[] =>
    fs.existsSync(abs(dir)) ? fs.readdirSync(abs(dir)).filter((f) => f.endsWith(".md")).map((f) => path.join(dir, f)) : [];
  this.files = [...list("plugin/commands"), ...list("plugin/agents"), "plugin/bdd-config.template.md"];
});

Then("none of them mentions {string} except as part of {string}", function (this: World, text: string, allowed: string) {
  const bad = this.files.filter((f) => read(f).split(allowed).join("").includes(text));
  assert.deepStrictEqual(bad, [], `names ${text} on its own: ` + bad.join(", "));
});

Then("none of them has a file name starting with {string}", function (this: World, start: string) {
  const bad = this.files.filter((f) => path.basename(f).startsWith(start));
  assert.deepStrictEqual(bad, [], `file name starts with ${start}: ` + bad.join(", "));
});

Then("the repo file {string} can be run", function (this: World, rel: string) {
  assert.ok((fs.statSync(abs(rel)).mode & 0o111) !== 0, `${rel} is not executable`);
});

const SKIPPED_FOLDERS = [".git", "docs", "results", "node_modules"];
const textFiles = (dir: string): string[] =>
  fs.readdirSync(abs(dir), { withFileTypes: true }).flatMap((e) => {
    const rel = dir === "" ? e.name : path.join(dir, e.name);
    if (e.isDirectory()) return SKIPPED_FOLDERS.includes(e.name) ? [] : textFiles(rel);
    if (!e.isFile()) return [];
    return fs.readFileSync(abs(rel)).includes(0) ? [] : [rel];
  });

Given("the text files of the repo outside docs", function (this: World) { this.files = textFiles(""); });

Then("none of them has an em-dash", function (this: World) {
  const bad = this.files.filter((f) => fs.readFileSync(abs(f), "utf8").includes(EM_DASH));
  assert.deepStrictEqual(bad, [], "files with an em-dash: " + bad.join(", "));
});

Then("every one starts with a frontmatter block and has a description or name line", function (this: World) {
  const bad = this.files.filter((f) => {
    const lines = read(f).split("\n");
    return lines[0] !== "---" || !lines.some((l) => /^(description|name):/.test(l));
  });
  assert.deepStrictEqual(bad, [], "no frontmatter, or no description or name: " + bad.join(", "));
});

Then("every skill role named in the config template has a command or agent file", function (this: World) {
  const roles = [...new Set([...this.subject.matchAll(/`bdd:([a-z-]*)`/g)].map((m) => m[1]))];
  assert.ok(roles.length > 0, "no skill roles found in the config template");
  const bad = roles.filter((r) => !fs.existsSync(abs(`plugin/commands/${r}.md`)) && !fs.existsSync(abs(`plugin/agents/${r}.md`)));
  assert.deepStrictEqual(bad, [], "roles with no skill file: " + bad.join(", "));
});

Then("it does not contain:", function (this: World, table: DataTable) {
  const bad = table.raw().flat().filter((t) => this.subject.includes(t));
  assert.deepStrictEqual(bad, [], "has: " + bad.join(", "));
});
