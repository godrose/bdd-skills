@flow-deliver
Feature: The CSV export fixture holds the acceptance example of issue 41

  Issue 41 gives one acceptance example: a user asks for a CSV export to include only the records that match the current filter, the plugin asks what happens when no record matches, the user says the download still works and has only the column headers, and the report says whether each example was checked. Fixture d is a small project for that story. A flow run of deliver on it reads the whole conversation.

  Decision (2026-11-12): The fixture starts with an export that ignores the filter and has one scenario. Why: the story is to make the export use the filter, so a run has a real change to specify, implement and look at.
  Decision (2026-11-12): The current filter is the file data/filter.json, and show.js prints the file that Export downloads for it. Why: step 5 of deliver looks at the real result, and the export has no screen here.
  Decision (2026-11-12): The persona is approver plus one answer, headers only when no record matches. Why: the issue gives that answer, and a run should not depend on a small model inventing it.
  Decision (2026-11-12): The scenarios run the harness against the fake claude and the fake npm, and the fixture project with node. Why: no login and no network, as for fixture c. The first real run needs the network once for the runner.

  Scenario: The fixture has what the harness needs
    Then these files exist:
      | flows/fixtures/d/persona.txt                      |
      | flows/fixtures/d/story-1.txt                      |
      | flows/fixtures/d/project/package.json             |
      | flows/fixtures/d/project/package-lock.json        |
      | flows/fixtures/d/project/cucumber.js              |
      | flows/fixtures/d/project/.claude/bdd-config.md    |
      | flows/fixtures/d/project/docs/out-of-scope.md     |
      | flows/fixtures/d/project/data/records.json        |
      | flows/fixtures/d/project/data/filter.json         |
      | flows/fixtures/d/project/src/export.js            |
      | flows/fixtures/d/project/src/filter.js            |
      | flows/fixtures/d/project/src/show.js              |
      | flows/personas/exporter.md                        |

  Scenario: The fixture has one feature file with one scenario
    Then fixture "d" holds 1 feature file
    Given the feature files of fixture "d"
    Then they hold 1 scenario

  Scenario: The story is the one in the issue
    Given the file "flows/fixtures/d/story-1.txt"
    Then it contains "include only the records that match the current filter"

  Scenario: The persona answers headers only when no record matches
    Given the file "flows/personas/exporter.md"
    Then it contains:
      | Approved                                      |
      | no records match                              |
      | contain only the column headers               |

  Scenario: The current filter is the open status
    Given the file "flows/fixtures/d/project/data/filter.json"
    Then it contains "open"

  Scenario: The export starts by ignoring the filter
    When the export script of the CSV fixture is run
    Then the output mentions:
      | id,name,status |
      | Q1 plan        |
      | Q2 plan        |
      | Audit          |

  Scenario: The export script shows the records file it is given
    Given a records file "data/_t.json" in the CSV fixture that holds:
      """
      [{"id":9,"name":"Emma","status":"open"}]
      """
    When the export script of the CSV fixture is run on "data/_t.json"
    Then the output mentions "9,Emma,open"
    And the output does not mention "Q1 plan"

  Scenario: The export script refuses a file outside the data folder
    When the export script of the CSV fixture is run on "../../../package.json"
    Then the run fails
    And the output mentions "data"

  Scenario: A deliver run on the fixture reads the story and plays the exporter persona
    Given the harness runs deliver on fixture "d" and story "1"
    And the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the assistant writes "features/filtered.feature" while it says message 3
    When the harness plays the conversation
    Then call 1 to the assistant contains:
      | /bdd:deliver Make the CSV export include only the records that match the current filter. |
    And the first prompt to the product manager model contains the first line of the persona card of the fixture
    And the rule "no-feature-before-go-ahead" is held
    And the rule "project-untouched" is held

  Scenario: An unknown fixture names all four
    Given the harness runs deliver on fixture "z" and story "1"
    When the harness plays the conversation
    Then the run fails
    And the output mentions "Use a, b, c or d."
