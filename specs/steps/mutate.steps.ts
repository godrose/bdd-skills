// Steps for tests/mutate.sh. The runner is run on a small sandbox project with its own test command, never on this repo.
import { Given, Then, When, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { ROOT, read, type World } from "./support";

type Sandbox = { root: string; breaks: string; extra: string[]; before: string };
const boxes = new WeakMap<World, Sandbox>();
const box = (w: World): Sandbox => {
  const b = boxes.get(w);
  assert.ok(b, "no sandbox project in this scenario");
  return b;
};

function makeBox(w: World, check: string): void {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "mutate-"));
  fs.writeFileSync(path.join(root, "code.txt"), "GOOD\n");
  fs.writeFileSync(path.join(root, "check.sh"), check);
  boxes.set(w, { root, breaks: path.join(root, "..", `${path.basename(root)}.tsv`), extra: [], before: "" });
}

Given("a sandbox project whose test passes while code.txt holds GOOD", function (this: World) { makeBox(this, "grep -q GOOD code.txt\n"); });
Given("a sandbox project whose test always fails", function (this: World) { makeBox(this, "exit 1\n"); });

Given("the breaks file holds:", function (this: World, table: DataTable) {
  const b = box(this);
  const lines = table.rows().map((row) => row.filter((c, i) => i < 3 || c !== "").join("\t"));
  fs.writeFileSync(b.breaks, [...b.extra, ...lines].join("\n") + "\n");
});
Given("the breaks file also has a comment line and a blank line before its breaks", function (this: World) {
  box(this).extra = ["# a comment", ""];
});

function run(w: World, args: string[]): void {
  const b = box(w);
  b.before = snapshot(b.root);
  const r = spawnSync("bash", [path.join(ROOT, "tests/mutate.sh"), "--root", b.root, "--cmd", "sh check.sh", ...args], { encoding: "utf8" });
  w.status = r.status;
  w.output = (r.stdout ?? "") + (r.stderr ?? "");
}
const snapshot = (dir: string): string =>
  fs.readdirSync(dir).sort().map((n) => `${n}:${fs.readFileSync(path.join(dir, n), "utf8")}`).join("|");

When("the mutation runner is run", function (this: World) { run(this, [box(this).breaks]); });
When("the mutation runner is run with {int} jobs", function (this: World, jobs: number) { run(this, ["--jobs", String(jobs), box(this).breaks]); });
When("the mutation runner is run on a breaks file that does not exist", function (this: World) { run(this, [path.join(box(this).root, "none.tsv")]); });

Then("the sandbox file {string} still reads {string}", function (this: World, name: string, text: string) {
  assert.strictEqual(fs.readFileSync(path.join(box(this).root, name), "utf8").trim(), text);
});
Then("the sandbox project is as it was before the run", function (this: World) {
  const b = box(this);
  assert.strictEqual(snapshot(b.root), b.before);
});
Then("the output lists {string} before {string}", function (this: World, first: string, second: string) {
  const a = this.output.indexOf(first), z = this.output.indexOf(second);
  assert.ok(a >= 0 && z >= 0 && a < z, this.output);
});

// The breaks files kept in the repo must still apply to the code they name, or they would report NOCHANGE.
Then("every break in {string} changes the file it names", function (this: World, rel: string) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "breaks-"));
  const stale: string[] = [];
  for (const line of read(rel).split("\n").filter((l) => l.trim() !== "" && !l.startsWith("#"))) {
    const [name, file, sub] = line.split("\t");
    const copy = path.join(tmp, "copy");
    fs.copyFileSync(path.join(ROOT, file), copy);
    spawnSync("perl", ["-0pi", "-e", sub, copy]);
    if (fs.readFileSync(copy, "utf8") === fs.readFileSync(path.join(ROOT, file), "utf8")) stale.push(name);
  }
  fs.rmSync(tmp, { recursive: true, force: true });
  assert.deepStrictEqual(stale, [], "breaks that no longer change their file: " + stale.join(", "));
});
Then("every line in {string} has a name, a file and a substitution", function (this: World, rel: string) {
  const bad = read(rel).split("\n").filter((l) => l.trim() !== "" && !l.startsWith("#")).filter((l) => {
    const f = l.split("\t");
    return f.length < 3 || f.length > 4 || f.slice(0, 3).some((x) => x === "") || (f[3] !== undefined && f[3] !== "equivalent") || !fs.existsSync(path.join(ROOT, f[1]));
  });
  assert.deepStrictEqual(bad, [], "malformed lines: " + bad.join(" | "));
});
