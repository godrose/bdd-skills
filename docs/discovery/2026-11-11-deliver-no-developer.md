# Discovery: `bdd:deliver` for a person with no developer

Input: known gap G12, the solo-founder case from the live runs of `discover`, a read of `plugin/commands/deliver.md`, and a discovery dialogue with the builder, one question at a time. The builder acts as product manager, developer and solo developer.

## Story

`deliver` works for a person who has no developer to hand technical stops to: a founder who is the product manager and the developer, or who cannot read the code. Today a parked technical stop goes into a "developer note" that such a person cannot act on.

## Existing behavior

- `deliver` names a developer in four places: the intro, the line about permission prompts, the rule that a technical stop is parked for the developer, and the "Developer note" in the report.
- `discover` Step 0 already treats roles as hats, keeps names out of findings and puts paths on one "For the developer" line. An unknown nobody can check becomes a listed assumption.
- The report has "couldn't be checked - why" but says nothing about what that means for the users.
- Not looked at: how `design`, `implement` and `run` word their own stops.

## Agreed examples

- **E1** A parked technical stop appears in the report under "Not checked, and what it risks": one plain sentence on what could go wrong for the users, then a "For the developer" line with the evidence.
- **E2** The example stays "couldn't be checked - <plain reason>". It is never "passed".
- **E3** The plain sentence names no file, field, function or status. Those go on the developer line only.
- **E4** With no parked stops, the section is left out.
- **E5** The "Developer note" stays for what was not recorded and for surprises seen in step 5.
- **E6** The intro says the command is for a product manager, with or without a developer. The permission line says the person running it approves each command and file write.
- **E7** `deliver` does not ask whether there is a developer, and has no different wording for a person without one.
- **E8** A product decision is still asked at once, one question.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | How does `deliver` know it is the no-developer case? | It does not. There is no mode. Every parked stop is a plain risk sentence plus a developer line. | The same shape as Step 0. One report for both people. An early question about the setup was turned down for `discover` and adds a question to every run. |
| 2 | Does the person answer something about a parked stop? | No. The report lists the risks and the person decides outside the run. | The report already ends the run and can be acted on. A closing question can be added later if a trial shows people skip the list. |
| 3 | The pin `a developer must` in the tests. | Replaced by a pin that the person running it approves each prompt. | A reversal: the earlier rule said a developer must answer the permission prompts. A person with no developer approves them. |
| 4 | When is G12 closed? | After a real run of `deliver` as a person with no developer reaches a report like this. | The text is pinned by tests only. The flow run for `deliver` (G7) shows it. |

## Existing users

- A project that updates the plugin sees the new section in the report. No config change, no new row, nothing installed or deleted.
- A team with a developer reads both parts of each risk. The "Developer note" stays.

## First run

A fresh project is unchanged until a stop is parked. Then the report shows the new section.

## Exclusions

- A mode, or an early question about the setup. Reason: decision 1.
- A closing question asking the person to accept the risks. Reason: decision 2.
- Changing how `design`, `implement` and `run` word their own stops. Reason: not read for this, and not needed for the report.
- Linking risks to a tracker (G8).
- A flow run of `deliver`. Reason: the next item. It closes G12.
