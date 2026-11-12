@skills-text
Feature: The README names the flow, the modes, the decision log and the rows

  These scenarios read the README. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The "## The flow" heading and the Optional config rows summary are not checked here. Why: readme-order and readme-folded hold them.

  Scenario: The README names the flow and the spec-only mode
    Given the README
    Then it contains:
      | bdd-discover  |
      | specify-only  |
      | workflow_mode |

  Scenario: The README names the spec modes and the discover step
    Given the README
    Then it contains:
      | --specify-and-implement              |
      | prints a note for each newer row     |
      | bdd:discover (optional first step    |
      | stops after the scenarios            |

  Scenario: The README describes the decision log and says @pending, not @manual
    Given the README
    Then it contains:
      | decision log  |
      | bdd-triage    |
      | bdd-reconcile |
      | jq            |
      | @pending      |
      | story page    |
    And it does not contain "tagged `@manual`"

  Scenario: The README says which scenarios are skipped and names the two roles
    Given the README
    Then it contains:
      | skip scenarios tagged                        |
      | checked by hand or waiting on the product    |
      | reconciler                                   |
      | feedback-intake                              |

  Scenario: The README lists the step_batch row, the list steps folder and the out-of-scope row
    Given the README
    Then it contains "| `step_batch` |"
    And it contains "comma-separated"
    And it contains "out_of_scope_file"
