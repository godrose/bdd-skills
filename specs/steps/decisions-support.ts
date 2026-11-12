// Helpers shared by the decision log step definitions.
import assert from "node:assert";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import type { DataTable } from "@cucumber/cucumber";
import { ROOT, type World } from "./support";

const SCRIPT = path.join(ROOT, "scripts/decisions.sh");
const GIT_ENV = { ...process.env, GIT_AUTHOR_NAME: "t", GIT_AUTHOR_EMAIL: "t@t", GIT_COMMITTER_NAME: "t", GIT_COMMITTER_EMAIL: "t@t" };

export const HEADER_ROW_FEATURE = `Feature: Export
  @spec-header-row @pending
  Scenario: Header row
    Given an order list
    When I export it
    Then the file has a header row
`;

export function newProject(world: World): void {
  if (world.dir) fs.rmSync(world.dir, { recursive: true, force: true });
  world.dir = fs.mkdtempSync(path.join(os.tmpdir(), `decisions-${process.pid}-`));
  fs.mkdirSync(path.join(world.dir, "docs/decisions"), { recursive: true });
  fs.mkdirSync(path.join(world.dir, "features"));
}

export function gitRun(world: World, ...args: string[]): { status: number; stdout: string } {
  const r = spawnSync("git", ["-c", "core.autocrlf=false", "-c", "commit.gpgsign=false", ...args], { cwd: world.dir, encoding: "utf8", env: GIT_ENV });
  return { status: r.status ?? -1, stdout: r.stdout.trim() };
}

export function git(world: World, ...args: string[]): string {
  const r = gitRun(world, ...args);
  assert.strictEqual(r.status, 0, `git ${args.join(" ")} failed`);
  return r.stdout;
}

export function commitAll(world: World, message: string): void {
  if (!fs.existsSync(path.join(world.dir, ".git"))) git(world, "init", "-q", "-b", "main");
  git(world, "add", "-A");
  git(world, "commit", "-q", "--allow-empty", "-m", message);
}

// Runs the script with stderr folded into stdout, as the old file did, and strips trailing newlines.
export function runScript(dir: string | undefined, args: string[], env: NodeJS.ProcessEnv = {}): { status: number; output: string } {
  const base = { ...process.env };
  delete base.BDD_DECISIONS_DIR;
  const r = spawnSync("/bin/bash", ["-c", 'exec /bin/bash "$0" "$@" 2>&1', SCRIPT, ...args], { cwd: dir ?? process.cwd(), encoding: "utf8", env: { ...base, ...env } });
  return { status: r.status ?? -1, output: r.stdout.replace(/\n+$/, "") };
}

export function run(world: World, args: string[], env: NodeJS.ProcessEnv = {}): void {
  world.run = { args, env };
  const r = runScript(world.dir, args, env);
  world.status = r.status;
  world.output = r.output;
}

export function fingerprintOf(world: World, id: string): string {
  const r = runScript(world.dir, ["fingerprint", id, "--features", "features"]);
  assert.strictEqual(r.status, 0, r.output);
  return r.output;
}

export const logPath = (world: World, name: string, folder = "docs/decisions"): string => path.join(world.dir, folder, `${name}.jsonl`);
export const featurePath = (world: World, rel: string): string => path.join(world.dir, "features", rel);

const storyOf = (id: string): string => id.slice(0, id.lastIndexOf("-"));

function effectOf(world: World, cell: string): Record<string, string> {
  let m = /^(adds|changes|rewords) (\S+) \((as it is now|fingerprint (\w+))\)$/.exec(cell);
  if (m) return { op: m[1], scenario: m[2], fp: m[4] ?? fingerprintOf(world, m[2]) };
  m = /^removes (\S+)$/.exec(cell);
  if (m) return { op: "removes", scenario: m[1] };
  m = /^excludes (.+)$/.exec(cell);
  if (m) return { op: "excludes", phrase: m[1] };
  m = /^defers (.+?)(?: \(reason: (.*)\))?$/.exec(cell);
  if (m) return m[2] === undefined ? { op: "defers", phrase: m[1] } : { op: "defers", phrase: m[1], reason: m[2] };
  throw new Error(`unknown effect: ${cell}`);
}

export function decisionLines(world: World, table: DataTable): string[] {
  return table.hashes().map((row) => {
    const rec: Record<string, unknown> = { v: 1, id: row.id, kind: "decision", story: storyOf(row.id), at: row.at, text: row.text };
    if ("effect" in row) rec.effects = row.effect ? [effectOf(world, row.effect)] : [];
    if (row.supersedes) rec.supersedes = [row.supersedes];
    if (row.resolves) rec.resolves = row.resolves;
    return JSON.stringify(rec);
  });
}

export function appendLines(world: World, name: string, lines: string[], folder = "docs/decisions"): void {
  fs.mkdirSync(path.join(world.dir, folder), { recursive: true });
  fs.appendFileSync(logPath(world, name, folder), lines.map((l) => l + "\n").join(""));
}

export function editFeature(world: World, rel: string, change: (text: string) => string): void {
  const file = featurePath(world, rel);
  fs.writeFileSync(file, change(fs.readFileSync(file, "utf8")));
}

export function section(output: string, heading: string): string {
  const lines = output.split("\n");
  const start = lines.findIndex((l) => l.includes(heading));
  assert.ok(start >= 0, `no ${heading} in: ${output}`);
  const next = lines.findIndex((l, i) => i > start && l.startsWith("## "));
  return lines.slice(start, next < 0 ? undefined : next).join("\n");
}
