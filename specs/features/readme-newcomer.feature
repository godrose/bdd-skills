@readme @newcomer
Feature: The README works for a reader new to BDD and to the plugin

  Decision (2026-11-13): The sections are checked for their place and their parts, not for their words. Why: the approach review cut phrase checks on prose.
  Decision (2026-11-13): Each row the minimum names must be a row of the config template. Why: a row that was renamed in the template would leave the README telling people to fill in a row that does not exist.
  Decision (2026-11-13): The README says the plugin does not install a runner, and names one per stack. Why: it is true today and a setup walk-through ages with the tool.

  Scenario: New to BDD comes after Contents and before Quick start
    Given the README
    Then it mentions these in this order:
      | ## Contents     |
      | ## New to BDD?  |
      | ## Quick start  |
    And it has a section "## New to BDD?" holding:
      | **BDD**              |
      | **Gherkin**          |
      | **scenario**         |
      | **step definition**  |
      | ```gherkin           |
      | Given                |
      | When                 |
      | Then                 |

  Scenario: Before you start comes before Quick start and links one runner per stack
    Given the README
    Then it mentions these in this order:
      | ## New to BDD?        |
      | ## Before you start   |
      | ## Quick start        |
    And it has a section "## Before you start" holding:
      | https://vitalets.github.io/playwright-bdd/ |
      | https://cucumber.io/docs/installation/     |
      | https://reqnroll.net/                      |

  Scenario: Configure has a minimum to start, and every row it names is in the config template
    Given the README
    Then it has a section "### Minimum to start" holding:
      | ```markdown |
    And every row named in the section "### Minimum to start" is a row of the config template

  Scenario: The flow says what the plugin writes
    Given the README
    Then it mentions these in this order:
      | ## The flow        |
      | ### What you get   |
      | ## Modes           |

  Scenario: Contents links the new sections
    Given the README
    Then it contains:
      | - [New to BDD?](#new-to-bdd)           |
      | - [Before you start](#before-you-start) |
