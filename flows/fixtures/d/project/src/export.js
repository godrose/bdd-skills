// Builds the CSV file that the Export button downloads: a header row, then one row per record.
const COLUMNS = ["id", "name", "status"];
function exportCsv(records) {
  const rows = records.map((r) => COLUMNS.map((c) => r[c]).join(","));
  return [COLUMNS.join(","), ...rows].join("\n") + "\n";
}
module.exports = { exportCsv };
