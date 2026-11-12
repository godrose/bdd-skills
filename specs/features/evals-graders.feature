@evals
Feature: The graders of the eval cases are named and counted as agreed

  Decision (2026-11-11): Exact facts are regex graders and only judgment goes to the judge. Why: it is the rule the old file enforced, by grader name and by count.
  Decision (2026-11-11): The judge counts cover five cases and not deliver-first-gate. Why: the old file counted only those five.

  Scenario: design-vague-ac grades what only the plugin does
    Given the file "evals/design-vague-ac/case.yaml"
    Then it contains:
      | name: has-step-reuse-audit             |
      | name: audit-has-asserts-column         |
      | name: tags-unautomated-in-specify-only |

  Scenario: design-vague-ac has regex graders for the two statuses
    Given the file "evals/design-vague-ac/case.yaml"
    Then it contains:
      | name: names-two-statuses      |
      | name: treats-finished-as-open |
    And it does not contain "name: flags-finished-as-ambiguous"

  Scenario: design-lint-draft has graders for the lint run and the files it leaves alone
    Given the file "evals/design-lint-draft/case.yaml"
    Then it contains:
      | name: runs-the-lint-row              |
      | name: draft-passes-lint              |
      | name: reports-old-findings-untouched |
      | name: no-edit-of-existing-files      |
      | name: no-draft-file-left             |
      | .bdd-draft-                          |

  Scenario: design-lint-draft judges one statement per criterion
    Given the file "evals/design-lint-draft/case.yaml"
    Then it contains:
      | name: scenarios-in-full                |
      | name: names-the-old-finding            |
      | name: no-claim-of-tagging-old-scenario |
    And it does not contain "scenarios-in-full-and-old-finding-not-fixed"

  Scenario: init-audit has regex graders for the path, the writing and the question
    Given the file "evals/init-audit/case.yaml"
    Then it contains:
      | name: says-path-does-not-exist |
      | name: no-claim-of-writing      |
      | name: asks-before-writing      |
    And it does not contain "name: reports-only-and-asks"

  Scenario: run-zero-tests has regex graders for the pass claim and the problem
    Given the file "evals/run-zero-tests/case.yaml"
    Then it contains:
      | name: not-reported-as-pass |
      | name: treats-as-a-problem  |

  Scenario: triage-approval-gate has regex graders for the questions and the records
    Given the file "evals/triage-approval-gate/case.yaml"
    Then it contains:
      | name: asks-per-item               |
      | name: no-claim-of-writing-records |
      | name: ok-not-counted-as-the-rules |
    And it does not contain "name: asks-per-item-and-does-not-claim-writes"

  Scenario Outline: No judge grader has a name that bundles two statements
    Given the file "evals/<case>/case.yaml"
    Then none of its judge graders has a compound name

    Examples:
      | case                 |
      | init-audit           |
      | design-vague-ac      |
      | triage-approval-gate |
      | run-zero-tests       |
      | design-lint-draft    |
      | deliver-first-gate   |

  Scenario Outline: A case has only the judge graders its judgment needs
    Given the file "evals/<case>/case.yaml"
    Then it has <judges> judge graders

    Examples:
      | case                 | judges |
      | design-vague-ac      | 1      |
      | init-audit           | 2      |
      | run-zero-tests       | 2      |
      | triage-approval-gate | 3      |
      | design-lint-draft    | 1      |
