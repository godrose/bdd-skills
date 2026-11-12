// Prints the file a user downloads with Export, for the filter in data/filter.json.
// It reads data/records.json, or another records file under data/ given as the first argument.
const path = require("path");
const { exportCsv } = require("./export");
const dataDir = path.resolve(__dirname, "../data");
const file = process.argv[2] ? path.resolve(process.cwd(), process.argv[2]) : path.join(dataDir, "records.json");
const rel = path.relative(dataDir, file);
if (rel.startsWith("..") || path.isAbsolute(rel)) {
  console.error("show.js reads only files under data/");
  process.exit(1);
}
const filter = require("../data/filter.json");
process.stdout.write(exportCsv(require(file), filter));
