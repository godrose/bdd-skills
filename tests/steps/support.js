// Helpers shared by the step definitions.
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const read = (rel) => fs.readFileSync(path.join(ROOT, rel), "utf8").replace(/\r\n/g, "\n");

// Every text file under the repo root, apart from the named folders. Binary files are skipped.
function textFiles(skipDirs, skipFiles = []) {
  const out = [];
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) { if (!skipDirs.includes(e.name)) walk(full); continue; }
      if (!e.isFile() || skipFiles.includes(e.name)) continue;
      const buf = fs.readFileSync(full);
      if (buf.subarray(0, 8000).includes(0)) continue;
      out.push(path.relative(ROOT, full));
    }
  };
  walk(ROOT);
  return out;
}

module.exports = { ROOT, read, textFiles };
