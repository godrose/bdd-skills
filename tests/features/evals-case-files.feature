@evals
Feature: Each eval case is complete

  Decision (2026-11-11): The six cases are Scenario Outlines over their names. Why: only the name differs, and the old file looped over the same list.
  Decision (2026-11-11): These scenarios read the files and run nothing. Why: the old file checked what the cases contain, and a migration adds no checks.

  Scenario Outline: The case has its files
    Given the repository
    Then the repo has these files:
      | evals/<case>/case.yaml   |
      | evals/<case>/scaffold.sh |
    And the repo has these folders:
      | evals/<case>/fixture |

    Examples:
      | case                 |
      | init-audit           |
      | design-vague-ac      |
      | triage-approval-gate |
      | run-zero-tests       |
      | design-lint-draft    |
      | deliver-first-gate   |

  Scenario Outline: The case file declares the schema, the scaffold and the graders
    Given the file "evals/<case>/case.yaml"
    Then it contains:
      | schema_version: "1.0"        |
      | scaffold_script: scaffold.sh |
      | graders:                     |
      | type: llm                    |
    And it has at least 2 graders

    Examples:
      | case                 |
      | init-audit           |
      | design-vague-ac      |
      | triage-approval-gate |
      | run-zero-tests       |
      | design-lint-draft    |
      | deliver-first-gate   |

  Scenario: The init-audit fixture has a config and no step definitions folder
    Given the repository
    Then the repo has these files:
      | evals/init-audit/fixture/.claude/bdd-config.md |
    And the repo has none of these paths:
      | evals/init-audit/fixture/src/step-defs |

  Scenario: The run-zero-tests fixture has a test script that runs no test
    Given the file "evals/run-zero-tests/fixture/fake-test.sh"
    Then it contains "No test matches"

  Scenario: The design-lint-draft fixture has a lint script and a feature file with an old finding
    Given the repository
    Then the repo has these files:
      | evals/design-lint-draft/fixture/fake-lint.sh             |
      | evals/design-lint-draft/fixture/features/reports.feature |

  Scenario: The design-lint-draft config names the lint script
    Given the file "evals/design-lint-draft/fixture/.claude/bdd-config.md"
    Then it contains "fake-lint.sh"

  Scenario: The lint script wants a ticket tag
    Given the file "evals/design-lint-draft/fixture/fake-lint.sh"
    Then it contains "@TKT-"

  Scenario: The old feature file in the lint fixture has no ticket tag
    Given the file "evals/design-lint-draft/fixture/features/reports.feature"
    Then it does not contain "@TKT-"
