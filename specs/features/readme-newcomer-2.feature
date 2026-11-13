@readme @newcomer-2
Feature: The README answers a newcomer's remaining questions

  Decision (2026-11-13): The checks are contracts between files: the install line names the marketplace of the marketplace file, every relative link points at a file, and the sections sit where they should. Why: the approach review of 2026-11-12.
  Decision (2026-11-13): The route to ask for access is the owner's GitHub profile. Why: a person without access cannot open an issue.
  Decision (2026-11-13): An empty typecheck row is a plugin text rule, in the verifier, in implement and in the template. Why: a README line alone would rest on what the agent happens to do.

  Scenario: The install line names the marketplace of the marketplace file
    Given the README
    Then its install line names the marketplace of the marketplace file

  Scenario: Quick start names the repository, the marketplace and the plugin
    Given the README
    Then it has a section "## Quick start" holding:
      | `godrose/bdd-skills`     |
      | `gennadyverdel-plugins` |
      | `bdd@gennadyverdel-plugins` |

  Scenario: The Access paragraph says how to ask the owner
    Given the README
    Then it has a section "## Install" holding:
      | [the owner](https://github.com/godrose) |

  Scenario: Every relative link in the README points at a file
    Given the README
    Then every relative link in it points at a file that exists
    And it contains:
      | ](CLAUDE.md)       |
      | ](flows/README.md) |
      | ](CHANGELOG.md)    |

  Scenario: The Glossary comes before Related projects and is linked from Contents
    Given the README
    Then it mentions these in this order:
      | ## Update           |
      | ## Glossary         |
      | ## Related projects |
    And it has a section "## Glossary" holding:
      | **Acceptance criteria**  |
      | **Discovery pack**       |
      | **Reuse audit**          |
      | **Verifier**             |
      | **Red-first**            |
      | **Headless run**         |
      | **Triage**               |
      | **Reconcile**            |
      | **Drift**                |
      | **Orphan**               |
    And it contains:
      | - [Glossary](#glossary) |

  Scenario: Before you start has a runner check and a line for stacks that are not listed
    Given the README
    Then it has a section "## Before you start" holding:
      | Not listed?     |
      | Behave          |
      | Behat           |
      | godog           |
      | run one example |

  Scenario: An empty typecheck row is skipped in the verifier, in implement and in the template
    Given the file "plugin/agents/verifier.md"
    Then it contains "If the row is absent, empty or in `<...>` form, skip this step and say so in one line."
    Given the plugin command "implement"
    Then it contains "skip any that is absent, empty or in `<...>` form and say so"
    Given the file "plugin/bdd-config.template.md"
    Then it contains "<command to check types / compile with strict warnings; empty to skip>"
