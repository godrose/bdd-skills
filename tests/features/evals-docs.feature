@evals
Feature: The evals guide and the CI guide say how to run the cases

  Decision (2026-11-11): The check that .gitignore lists evals/results/ is not written again. Why: layout-wiring.feature already has it.

  Scenario: The installer does not copy the evals into a project
    Given the file "install.sh"
    Then it does not contain "evals"

  Scenario: The evals guide gives the cost-aware defaults
    Given the file "evals/README.md"
    Then it contains:
      | claude plugin eval                |
      | --scaffold                        |
      | --no-publish                      |
      | --ablation none                   |
      | --runs 1                          |
      | usage                             |
      | --judge-model sonnet              |
      | ## What the spike found           |
      | Not measured                      |
      | Full run: 4 cases                 |
      | Baseline run                      |
      | Baseline with plugin-only graders |
      | A rubric must state the property  |

  Scenario: The evals guide lists design-lint-draft and grants Bash for that case only
    Given the file "evals/README.md"
    Then it contains:
      | design-lint-draft                                      |
      | --case design-lint-draft --allow-tools Write Edit Bash |
      | only for this case                                     |

  Scenario: The evals guide grants run-zero-tests a read-only shell
    Given the file "evals/README.md"
    Then it contains:
      | --case run-zero-tests |
      | "Bash(echo:*)"        |

  Scenario: The evals guide lists the deliver gate case
    Given the file "evals/README.md"
    Then it contains:
      | \| `deliver-first-gate` \|   |
      | two questions in one message |

  Scenario: The CI guide says which cases run nightly and how the job reports
    Given the file "docs/evals-ci.md"
    Then it contains:
      | five of the six cases   |
      | setup-token             |
      | ## In CI                |
      | EVALS_NIGHTLY           |
      | only when the job fails |
