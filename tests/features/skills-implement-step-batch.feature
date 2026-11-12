@skills-text
Feature: The implement command groups steps by risk and reports the plan

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The old file reversed two rules: a step is classified by what needs a run to know, and the plan goes in the final report. Why: the model writes the report reliably, and code that is new can still be written by reading the repo.

  Scenario: The command plans groups by risk and splits a failing group
    Given the plugin command "implement"
    Then it contains:
      | Plan the groups                         |
      | step_batch                              |
      | classify it high                        |
      | A high step closes the group            |
      | split the rest of that group in half    |
      | does not wait for approval              |
      | existing, no work                       |

  Scenario: The group plan comes before the first run
    Given the plugin command "implement"
    Then it mentions these in this order:
      | Plan the groups        |
      | ##### 2a. Run the test |

  Scenario: A step is classified by what needs a run to know
    Given the plugin command "implement"
    Then it contains:
      | you can write by reading the repo                    |
      | knowledge you cannot get by reading the repo         |
      | the state of a rendered page                         |
    And it does not contain "needs a new element, endpoint, client method or fixture"

  Scenario: The group plan reaches the person in the final report
    Given the plugin command "implement"
    Then it contains:
      | add a **Groups** section |
      | the number of test runs  |
    And it does not contain:
      | write the plan as a message                    |
      | Print one line per step before the first run   |
