import { Given, When, Then } from "./fixtures";

Given("the records page lists {int} records", async ({ page }, count: number) => {});
When("I export the records to CSV", async ({ page }) => {});
Then("the CSV has {int} rows and a header row", async ({ page }, rows: number) => {});
