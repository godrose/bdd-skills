// Helpers shared by the install step definitions.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { ROOT, type World } from "./support";

export const tmp = (prefix: string): string => fs.mkdtempSync(path.join(os.tmpdir(), prefix));

export const claude = (world: World, rel: string): string => path.join(world.dir, ".claude", rel);

export const readClaude = (world: World, rel: string): string => fs.readFileSync(claude(world, rel), "utf8").replace(/\r\n/g, "\n");

// The installer under test: the repo's own, or a copy kept outside the repo with a stub git beside it.
export const installerPath = (world: World): string => (world.bin ? path.join(world.bin, "install.sh") : path.join(ROOT, "install.sh"));

export const toolLines = (text: string): string[] => text.split("\n").filter((l) => l.startsWith("allowed-tools:"));
