import { createBdd } from "playwright-bdd";
const { Given, When, Then } = createBdd();
Given("the report {string} is {word}", async ({ page }, name: string, status: string) => {});
When("I share {string}", async ({ page }, name: string) => {});
Then("{string} shows as shared", async ({ page }, name: string) => {});
