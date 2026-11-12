import { After, Given, When } from "@cucumber/cucumber";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { ROOT, read, type World } from "./support";
import { claude, installerPath, tmp } from "./install-support";

function put(world: World, rel: string, text: string): void {
  fs.mkdirSync(path.dirname(claude(world, rel)), { recursive: true });
  fs.writeFileSync(claude(world, rel), text);
}

function bash(world: World, script: string, args: string[], cwd: string, env: NodeJS.ProcessEnv): void {
  const r = spawnSync("bash", [script, ...args], { cwd, env, encoding: "utf8" });
  world.status = r.status;
  world.output = (r.stdout ?? "") + (r.stderr ?? "");
}

// A copy of the installer outside the repo, so it has to clone, with a git that never touches the network.
function installerWithGit(world: World, exitCode: number): void {
  world.bin = tmp("installer-");
  fs.mkdirSync(path.join(world.bin, "bin"));
  fs.copyFileSync(path.join(ROOT, "install.sh"), path.join(world.bin, "install.sh"));
  fs.writeFileSync(path.join(world.bin, "bin/git"), `#!/bin/sh\necho "Cloning into stub"\nexit ${exitCode}\n`, { mode: 0o755 });
}

After(function (this: World) {
  for (const d of [this.dir, this.bin]) if (d) fs.rmSync(d, { recursive: true, force: true });
});

Given("a project with no .claude folder", function (this: World) { this.dir = tmp("install-"); });

Given("a project whose config reads:", function (this: World, text: string) {
  this.dir = tmp("install-");
  put(this, "bdd-config.md", text + "\n");
});

Given("a project with its own file {string} that reads {string}", function (this: World, rel: string, text: string) {
  this.dir = tmp("install-");
  put(this, rel, text + "\n");
});

Given("an installer whose git fails to clone", function (this: World) { installerWithGit(this, 1); });

Given("an installer whose git clones a source with no plugin folder", function (this: World) { installerWithGit(this, 0); });

Given("the installer", function (this: World) { this.subject = read("install.sh"); });

When("the installer is run on it", function (this: World) {
  const env = this.bin ? { ...process.env, PATH: `${path.join(this.bin, "bin")}:${process.env.PATH}` } : process.env;
  bash(this, installerPath(this), [this.dir], this.bin || ROOT, env);
});

When("the installed decisions script is run with {string}", function (this: World, arg: string) {
  bash(this, ".claude/scripts/decisions.sh", [arg], this.dir, process.env);
});

When("the line {string} is added to the installed file {string}", function (this: World, line: string, rel: string) {
  fs.appendFileSync(claude(this, rel), line + "\n");
});

When("a copy of the installed file {string} is kept", function (this: World, rel: string) {
  this.kept = fs.readFileSync(claude(this, rel), "utf8");
});
