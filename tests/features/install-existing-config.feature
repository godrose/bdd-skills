@install
Feature: A project that already has a config keeps it

  A project that adopted an earlier version has a bdd-config.md of its own. The installer
  leaves it unchanged and names the rows that the newer template has and the config lacks.

  Decision (2026-11-11): Each scenario installs into its own project. Why: the old file shared one project across many checks, so a check could pass on what an earlier one left behind.
  Decision (2026-11-11): Messages are checked as the old file checked them, by the text they contain. Why: a migration adds no checks.
  Decision (2026-11-11): A title names only what its steps check. Why: the old file checks that a row name appears in the output, not that a note is worded a certain way.
  Decision (2026-11-11): The 16 rows stay in one Scenario Outline. Why: only the row differs, and the builder chose the shorter form.

  Scenario: A config from an earlier version is left unchanged
    Given a project whose config reads:
      """
      SENTINEL
      """
    When the installer is run on it
    Then the installed file "bdd-config.md" holds only the line "SENTINEL"

  Scenario Outline: The installer names the <row> row when the config lacks it
    Given a project whose config reads:
      """
      SENTINEL
      """
    When the installer is run on it
    Then the output mentions "<row>"

    Examples:
      | row                |
      | workflow_mode      |
      | unautomated_tag    |
      | automated_tag      |
      | decision_log       |
      | decisions_dir      |
      | scenario_id_prefix |
      | status_scope       |
      | manual_only_tag    |
      | blocked_tag        |
      | reconciler         |
      | feedback-intake    |
      | prepare            |
      | step_batch         |
      | planned_dir        |
      | manual_only_dir    |
      | out_of_scope_file  |

  Scenario: The installer names @pending when the config lacks the unautomated_tag row
    Given a project whose config reads:
      """
      SENTINEL
      """
    When the installer is run on it
    Then the output mentions "@pending"

  Scenario: Only a table row counts as a config row, not a mention in prose
    Given a project whose config reads:
      """
      we discuss workflow_mode here
      |lint|x|
      """
    When the installer is run on it
    Then the output mentions "no 'workflow_mode' row"
    And the output does not mention "no 'lint' row"
