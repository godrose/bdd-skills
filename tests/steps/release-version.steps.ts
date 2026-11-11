import { Given, When } from "@cucumber/cucumber";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { ROOT, type World } from "./support";

const GIT_ENV = { ...process.env, GIT_AUTHOR_NAME: "t", GIT_AUTHOR_EMAIL: "t@t", GIT_COMMITTER_NAME: "t", GIT_COMMITTER_EMAIL: "t@t" };

function git(dir: string, ...args: string[]): void {
  const r = spawnSync("git", args, { cwd: dir, encoding: "utf8", env: GIT_ENV });
  if (r.status !== 0) throw new Error(`git ${args.join(" ")} failed: ${r.stderr}`);
}

const manifest = (version: string | null): string => JSON.stringify(version === null ? { name: "bdd" } : { name: "bdd", version }) + "\n";

// A throwaway repo whose main holds the release check scripts and a plugin at the given place and version.
function mainWith(world: World, version: string | null, oldRoot: boolean): void {
  world.dir = fs.mkdtempSync(path.join(os.tmpdir(), "release-"));
  const plugin = oldRoot ? world.dir : path.join(world.dir, "plugin");
  fs.mkdirSync(path.join(world.dir, "tests"));
  fs.copyFileSync(path.join(ROOT, "tests/lib.sh"), path.join(world.dir, "tests/lib.sh"));
  fs.mkdirSync(path.join(plugin, ".claude-plugin"), { recursive: true });
  fs.mkdirSync(path.join(plugin, "commands"));
  fs.writeFileSync(path.join(plugin, ".claude-plugin/plugin.json"), manifest(version));
  fs.writeFileSync(path.join(plugin, "commands/x.md"), "a\n");
  git(world.dir, "init", "-q", "-b", "main");
  git(world.dir, "add", "-A");
  git(world.dir, "commit", "-q", "-m", "base");
}

function branch(world: World, version: string, edit: () => void): void {
  git(world.dir, "checkout", "-q", "-b", "release");
  edit();
  fs.writeFileSync(path.join(world.dir, "plugin/.claude-plugin/plugin.json"), manifest(version));
  git(world.dir, "add", "-A");
  git(world.dir, "commit", "-q", "--allow-empty", "-m", "change");
}

Given("a main where the plugin has version {string}", function (this: World, version: string) { mainWith(this, version, false); });
Given("a main where the plugin has no version", function (this: World) { mainWith(this, null, false); });
Given("a main where the plugin sits at the old repo root with version {string}", function (this: World, version: string) { mainWith(this, version, true); });

Given("a release branch that sets the version to {string}", function (this: World, version: string) {
  branch(this, version, () => {});
});
Given("a release branch that changes a plugin command and sets the version to {string}", function (this: World, version: string) {
  branch(this, version, () => fs.appendFileSync(path.join(this.dir, "plugin/commands/x.md"), "b\n"));
});
Given("a release branch that moves the plugin into the plugin folder and sets the version to {string}", function (this: World, version: string) {
  branch(this, version, () => {
    fs.mkdirSync(path.join(this.dir, "plugin"));
    git(this.dir, "mv", ".claude-plugin", "plugin/.claude-plugin");
    git(this.dir, "mv", "commands", "plugin/commands");
  });
});

const CHECKS: Record<string, string> = {
  "plugin changed": "assert_version_bumped",
  "version is higher": "assert_version_higher",
};

When("the {string} check is run", function (this: World, check: string) {
  const fn = CHECKS[check];
  if (!fn) throw new Error(`unknown check: ${check}`);
  const r = spawnSync("bash", ["-c", `ROOT="$PWD"; . tests/lib.sh; ${fn}; finish`], { cwd: this.dir, encoding: "utf8" });
  this.status = r.status;
  this.output = (r.stdout || "") + (r.stderr || "");
});
