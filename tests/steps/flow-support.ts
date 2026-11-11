// Helpers shared by the flow harness step definitions. They play flows/run.sh against the fake claude and fake npm of tests/fixtures.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { ROOT, type World } from "./support";

export const FLOWS = path.join(ROOT, "flows");
export const FIXTURE_PROJECT = path.join(FLOWS, "fixtures/c/project");

export const MESSAGES = {
  checklist: `What exists: one scenario covers part of it.

E1. A late loan shows how many days late it is.
E2. The notice stays in view when the member scrolls.

Do you approve this checklist?`,
  scenarios: `Here are the scenarios in plain words.

Do you approve these scenarios?`,
  extraAsk: "Please approve the checklist once more?",
  cleanReport: `Delivered: A late loan shows its days late.

E1 A late loan shows how many days late it is: passed
E2 The notice stays in view when the member scrolls: passed

Regression: 1 earlier scenario still passes.
Seen: opened the loans page on the same data.`,
  parkedReport: `Delivered: A late loan shows its days late.

E1 A late loan shows how many days late it is: passed
E2 The notice stays in view when the member scrolls: couldn't be checked - needs a real browser

Regression: 1 earlier scenario still passes.
Seen: opened the loans page on the same data.

Not checked, and what it risks:
- E2 Members may scroll past the notice and miss it. For the developer: needs a real browser to check.`,
};

export const TEST_OUTPUT = {
  passed: "2 scenarios (2 passed)\n6 steps (6 passed)\n",
  pending: "2 scenarios (1 pending, 1 passed)\n6 steps (1 pending, 5 passed)\n",
  none: "0 scenarios\n0 steps\n",
};

// What one scenario sets up and what its last play left behind.
export type Flow = {
  tmp: string;
  messages: string[];
  replies: Map<number, string>;
  write: { file: string; at: number } | null;
  testOutput: string;
  installFails: boolean;
  plays: number;
  scriptDir: string;
  outDir: string;
  harness: string;
  fixtureFiles: string[];
  scenarioCount: number;
  reports: string[];
  command: string;
  fixture: string;
  story: string;
  turns: number | null;
  relativeOut: boolean;
  noClaude: boolean;
};

export function flow(world: World): Flow {
  if (!world.flow) {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "flow-"));
    const bin = path.join(tmp, "bin");
    fs.mkdirSync(bin);
    for (const [from, to] of [["fake-claude.sh", "claude"], ["fake-npm.sh", "npm"]]) {
      fs.copyFileSync(path.join(ROOT, "tests/fixtures", from), path.join(bin, to));
      fs.chmodSync(path.join(bin, to), 0o755);
    }
    fs.writeFileSync(path.join(tmp, "npm.log"), "");
    world.flow = {
      tmp, messages: [], replies: new Map(), write: null, testOutput: TEST_OUTPUT.passed, installFails: false, plays: 0,
      scriptDir: "", outDir: "", harness: path.join(FLOWS, "run.sh"), fixtureFiles: [], scenarioCount: 0, reports: [],
      command: "deliver", fixture: "c", story: "1", turns: null, relativeOut: false, noClaude: false,
    };
  }
  return world.flow;
}

export const cacheDir = (f: Flow): string => path.join(f.tmp, "cache");
export const npmLog = (f: Flow): string => path.join(f.tmp, "npm.log");
export const baseDir = (f: Flow): string => path.join(f.outDir, f.story ? `${f.fixture}-story-${f.story}` : f.fixture);
export const runDir = (f: Flow): string => path.join(baseDir(f), "run-1");

// One run of the harness, by default deliver on fixture c, story 1. The messages come from the script folder. A deliver run answers "Approved" to the first two.
export function play(world: World, harness: string = path.join(FLOWS, "run.sh")): void {
  const f = flow(world);
  f.plays += 1;
  f.harness = harness;
  f.scriptDir = path.join(f.tmp, `script-${f.plays}`);
  f.outDir = path.join(f.tmp, `out-${f.plays}`);
  fs.mkdirSync(f.scriptDir);
  f.messages.forEach((m, i) => {
    fs.writeFileSync(path.join(f.scriptDir, `assistant-${i + 1}.txt`), m + "\n");
    fs.writeFileSync(path.join(f.scriptDir, `pm-${i + 1}.txt`), (f.command === "deliver" && i < 2 ? "Approved" : `A. reply ${i + 1}`) + "\n");
  });
  for (const [n, text] of f.replies) fs.writeFileSync(path.join(f.scriptDir, `pm-${n}.txt`), text + "\n");
  const npmOut = path.join(f.tmp, "npm-out.txt");
  fs.writeFileSync(npmOut, f.testOutput);
  const env: NodeJS.ProcessEnv = {
    ...process.env,
    PATH: `${path.join(f.tmp, "bin")}:${process.env.PATH}`,
    NPM_BIN: path.join(f.tmp, "bin/npm"),
    FAKE_NPM_LOG: npmLog(f),
    FLOWS_CACHE: cacheDir(f),
    FAKE_DIR: f.scriptDir,
    FAKE_NPM_OUT: npmOut,
    FAKE_WRITE_AT: f.write ? String(f.write.at) : "",
    FAKE_WRITE_FILE: f.write ? f.write.file : "",
  };
  if (f.installFails) env.FAKE_NPM_FAIL = "1";
  if (f.noClaude) env.CLAUDE_BIN = "no-such-claude-binary";
  const args = [harness, "--command", f.command, "--fixture", f.fixture, ...(f.story ? ["--story", f.story] : []), "--runs", "1"];
  if (f.turns !== null) args.push("--turns", String(f.turns));
  args.push("--out", f.relativeOut ? path.basename(f.outDir) : f.outDir);
  const r = spawnSync("bash", args, { env, encoding: "utf8", cwd: f.relativeOut ? f.tmp : undefined });
  world.status = r.status;
  world.output = (r.stdout ?? "") + (r.stderr ?? "");
}

export const readReport = (world: World): string => fs.readFileSync(path.join(baseDir(flow(world)), "report.md"), "utf8");
export const readRun =(world: World, name: string): string => fs.readFileSync(path.join(runDir(flow(world)), name), "utf8");
