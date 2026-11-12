const { Given, When, Then } = require("@cucumber/cucumber");
const { exportCsv } = require("../src/export");
let records = [];
let csv = "";
Given("the records page lists {int} records", (count) => {
  records = Array.from({ length: count }, (_, i) => ({ id: i + 1, name: `Record ${i + 1}`, status: "open" }));
});
When("I export the records to CSV", () => { csv = exportCsv(records); });
Then("the CSV has {int} rows and a header row", (rows) => {
  const lines = csv.trim().split("\n");
  if (lines.length !== rows + 1) throw new Error(`${lines.length} lines`);
  if (lines[0] !== "id,name,status") throw new Error(lines[0]);
});
