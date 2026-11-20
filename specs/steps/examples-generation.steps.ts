import { Then } from "@cucumber/cucumber";
import assert from "node:assert";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { ROOT, type World } from "./support";

const sha256 = (data: string | Buffer): string => crypto.createHash("sha256").update(data).digest("hex");

// The pin is "pinned to tag `<tag>`" followed by "Its SHA-256 at that tag is `<sha>`".
export function guardPin(text: string): { tag: string; sha: string } | null {
  const tag = text.match(/pinned to tag `([^`]+)`/)?.[1];
  const sha = text.match(/Its SHA-256 at that tag is `([0-9a-f]{64})`/)?.[1];
  return tag && sha ? { tag, sha } : null;
}

Then("its guard pin matches the script at the pinned tag, or scripts\\/examples.sh while that tag does not exist", function (this: World) {
  const pin = guardPin(this.subject);
  assert.ok(pin, "no guard pin (a tag and a SHA-256) in the text");
  const atTag = spawnSync("git", ["show", `${pin.tag}:scripts/examples.sh`], { cwd: ROOT });
  const tagged = spawnSync("git", ["rev-parse", "-q", "--verify", `refs/tags/${pin.tag}`], { cwd: ROOT }).status === 0;
  if (tagged) {
    assert.strictEqual(atTag.status, 0, `tag ${pin.tag} has no scripts/examples.sh`);
    assert.strictEqual(pin.sha, sha256(atTag.stdout), `the pin says ${pin.sha}, the script at ${pin.tag} is ${sha256(atTag.stdout)}`);
  } else {
    const here = sha256(fs.readFileSync(path.join(ROOT, "scripts/examples.sh")));
    assert.strictEqual(pin.sha, here, `tag ${pin.tag} does not exist yet, and the pin says ${pin.sha} while scripts/examples.sh is ${here}`);
  }
});
