import { createBdd } from "playwright-bdd";
const { Given, When, Then } = createBdd();
Given("the experiment {string} is {word}", async ({ page }, name: string, status: string) => {});
When("I delete {string}", async ({ page }, name: string) => {});
When("I try to delete {string}", async ({ page }, name: string) => {});
Then("{string} is no longer listed", async ({ page }, name: string) => {});
Then("the delete is refused", async ({ page }) => {});
