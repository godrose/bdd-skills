@readme @newcomer-3
Feature: The README helps a newcomer choose a path and start safely

  Decision (2026-11-13): The chooser sits at the top of The flow and names both paths. Why: a developer chooses before reading the steps.
  Decision (2026-11-13): The runner check points at the runner's own getting-started page. Why: a do-nothing step differs in every runner.

  Scenario: The flow starts with a chooser that names both paths
    Given the README
    Then it mentions these in this order:
      | ## The flow             |
      | ### Which path?         |
      | For an individual builder: |
    And it has a section "### Which path?" holding:
      | /bdd:deliver  |
      | /bdd:discover |
      | /bdd:design   |
      | /bdd:implement |

  Scenario: Before you start asks for a branch and a runner check from the runner's own page
    Given the README
    Then it has a section "## Before you start" holding:
      | a branch               |
      | getting-started page   |
    And it does not contain:
      | one `Given` step that does nothing |

  Scenario: What you get says who creates the starting state of a scenario
    Given the README
    Then it has a section "### What you get" holding:
      | `Given` step  |
      | setup error   |
