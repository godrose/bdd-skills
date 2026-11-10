# A product manager delivers two changes with `/bdd:deliver`

A record of one working session, kept as an example of how a product manager talks to the plugin through this command. Read it to see the shape of the conversation, the questions a product manager is asked, where they push back, and what the pushback changed.

## What this is, and what it is not

- Two changes were delivered on a real project, one after the other, in one session. The project is a .NET experiment runner with a web client and two test suites. It is the same project as in `docs/discovery/2026-11-04-dogfood-bdd-netcore.md`. Its name and paths are left out here.
- The assistant followed `plugin/commands/deliver.md` step by step. Not run through the command itself: nobody typed `/bdd:deliver`. This tests the method and the text of the command, not how the command behaves in a live session.
- In this session the plugin author played the product manager. They know the method well, so this is not a test with a person who has never seen it. Where the product manager was confused, that is marked below, and those moments are the most useful ones.
- The product manager's words are quoted as they were written. The assistant's messages are summarized.

## How the conversation is shaped

This is what a product manager sees. None of it needs code or test knowledge.

- **One question at a time.** Each question names the behavior in plain words, gives two or three lettered options, and says which one the assistant would pick and why.
- **A default is always offered.** The answer can be one letter. In the 16 answers in the two tables below, 9 were a single letter.
- **Findings come before the question.** When the code showed something nobody had described, the assistant said what it found, in a short list, and then asked.
- **Two gates.** First the product manager approves a numbered checklist of agreed examples. Then someone approves the scenarios as plain sentences, and only then is a file written.
- **The assistant does not ask twice.** The approved checklist counts as the approval of the examples, so the second gate shows scenarios, not examples again.
- **A stop is classified.** A product decision (what should this do?) is asked at once. A technical stop (a step failed three times) is parked and reported to the developer.

## Trial 1: specify and fix deleting an experiment

The behavior already existed and had no scenarios.

| What the assistant said | The product manager answered | What was recorded |
|---|---|---|
| Delete works for every status except Running. Should a Draft, Completed, Failed or Cancelled experiment be deletable as the code allows? | "Keep existing behavior" | Example E1, from code |
| Deleting an experiment that no longer exists: A, a clear refusal, B, silent success, C, leave it. | "A" | Example E3 (new) |
| Should the user be asked before a completed experiment is deleted for good? | "A" | The assistant then found that the screen already asks. Example E5 became "already works". |
| The screen blocks Delete for a Starting experiment but the server allows it. Protect it? | "A" | Example E4 (new) |
| The checklist of six examples, E1 to E6, with what is out of scope. | "Let's move in with this suggestion" | First approval |
| The scenarios in plain words and as text, with a reuse audit table. | "Keep separate scenarios for the readability and the go ahead" | Second approval, after one question about layout |
| Running the new scenarios first: 5 of 7 pass, 2 fail. The failing one shows a message that repeats itself and leaks a status code. Which wording? | "Clean wording" | A product stop, asked at once |

The result: 10 scenarios (7 on the server, 3 on the screen), one real defect fixed, one message cleaned up, and a report with one line per example. The first report was:

```
Delivered: Deleting an experiment is safe and specified. ...
E1 Deleting a Draft, Completed, Failed or Cancelled experiment removes it: passed (4 scenarios)
E2 A Running experiment can't be deleted, and stays: passed
E3 A missing experiment is refused with "Experiment 1 was not found": passed
E4 A Starting experiment can't be deleted, and stays: passed
E5 The screen asks "Are you sure?", confirming deletes and declining keeps it: passed
E6 The Delete button is disabled for a Running experiment: passed
Regression: all 22 server scenarios pass, and all 16 end-to-end scenarios pass.
```

## Trial 2: how long an experiment waited and ran

New functionality across two services and the client.

| What the assistant said | The product manager answered | What was recorded |
|---|---|---|
| When does the clock start: when the user presses Run, or when the job begins running? | "That's a very good question. Do we want to measure both? What is the best practice?" | The assistant explained: store the moments, not the duration. The design became three moments (Run pressed, Began running, Ended) and two durations. |
| Three moments, run time in the list, both in the details? | "A" | The scope |
| What does Run time show for a Failed or Cancelled run? | "A" (the time until it ended) | Examples E3, E4, E5 |
| What does a run show while it is still Running? | "A" (a dash) | Example E6; a live counter is out of scope |
| A Failed experiment can be run again. Keep a history, or only the latest? | "A" (only the latest) | Example E8; history is out of scope |
| How should a time read: `1 min 23 s` or `00:01:23`? | "A" (plain units) | Example E11 |
| The checklist of 11 examples, with what is out of scope. | "usually in the real world these out-of-scope scenarios might be mapped to a different ticket in JIRA, Monday, etc. Let's adopt the out-of-scope for now and document this somewhere as a possible enhancement to the process" | First approval, and the idea recorded as known gap G8 |
| Reading the code to design the scenarios showed that only a polling service notices when a job starts or ends, so times are accurate to half a second. Accept it? | "A" | A product decision, asked late (see below) |
| The scenarios and the audit table. | "go ahead" | Second approval |

The result: 15 scenarios at the first go-ahead (11 on the server, 4 on the screen), 18 after the screen check described below (12 and 6), and a feature across the data service, the facade, the sync service and the client.

## Where the product manager was confused or pushed back

These are the moments that changed the method.

1. **"What do you mean cancelled and failed in one scenario? Is this scenario outline or something else?"** The assistant had offered to "fold" two scenarios into one without saying what that meant. The real choice was a Scenario Outline against separate scenarios. The product manager chose separate ones for readability. Lesson: offer that choice by its name and consequence.
2. **"Do we want to measure both? What is the best practice?"** The product manager reframed a narrow question about a start point into a design question. It changed the model for the whole feature. Lesson: the assistant should be ready to answer "what is the best practice?" with a recommendation, not only options.
3. **"It's not clear what the status is right now. What's the functionality that had been added? Where can I see the features/scenarios?"** After the work, the assistant's summary was too long and too technical. The answer that worked was three short parts: what was added, where the files are, where the pull requests are. Lesson: the report at the end is for the product manager, so it needs the shortest form that says where to look.
4. **"Produce the option 2"** (a screenshot of the running app). Looking at the screens found two problems that no test could fail on. The list showed Draft for two examples the scenarios called Starting and Running, because the data file declared a status that the sync service reverted at once. The details page had an empty leftover row.
5. **"Why weren't these problems highlighted during the automation execution?"** The honest answer was that the scenarios checked less than their titles said, and nothing compared the declared state with what the system showed. This added step 5, "Look at the result", to the command.
6. **"Why does `bdd:deliver` add something that overlaps with the verifier? ... what does it mean to verify? Is this a flaw in specification or somewhere else?"** The verifier runs the tests, so it answers whether scenarios pass, not whether they are right. The flaw started in design: nothing checks that a scenario asserts what its title claims. This led to the next discovery.

## What the product manager never had to do

- Read or write a step definition, a data file or a test.
- Decide anything about layers, files or frameworks. Those stops were parked for the developer.
- Approve the same thing twice.
- Chase a status. The assistant reported failures and passes in the same shape each time.

## What was less good

- The late stop in trial 2. The question about timing precision belonged in discovery, before the checklist was approved. The code that showed it was read only at design.
- Two statements the assistant had to correct: that no screen showed dates (the list had a "Created on" column), and that the first discovery found no delete scenarios (one screen check already existed).
- The final answers grew long. A product manager asked for the status in the middle of the work.

## What this record points to

The method changes it led to, all in the pull request that added `deliver`:

- Look at the result before reporting (step 5, decisions 17 to 21 of the discovery pack).
- Five suggestions in the pull request description: scan existing scenarios and screens before the first question, ask where the shown state comes from, put the failing step before product code in every layer, offer Outline against separate scenarios by name, and ask at the end which excluded items should become tickets.
- Known gap G8 for out-of-scope items and trackers.
- A next discovery for `bdd:design`: check that each scenario asserts what its title claims, and that every state the data declares can be observed. See the handoff note for that session.

## Limits as evidence

One session, one project, one product manager who wrote the method. It shows what the conversation looks like and which parts held. It does not show that a person new to the method can follow it. A trial with such a person, running `/bdd:deliver` itself, is still to do.
