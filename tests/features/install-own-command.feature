@install
Feature: A user's own command with the same name is kept

  A project may have its own commands/bdd-deliver.md. The installer overwrites its own copies,
  which start with a "# Source:" line, and leaves any other file of that name alone.

  Decision (2026-11-11): Each scenario installs into its own project. Why: the old file shared one project across many checks, so a check could pass on what an earlier one left behind.
  Decision (2026-11-11): Messages are checked as the old file checked them, by the text they contain. Why: a migration adds no checks.
  Decision (2026-11-11): A title names only what its steps check. Why: the old file checks that the file name and the word "skipped" appear in the output, not that they appear together.

  Scenario: A user's own deliver command is left unchanged
    Given a project with its own file "commands/bdd-deliver.md" that reads "MY OWN COMMAND"
    When the installer is run on it
    Then the installed file "commands/bdd-deliver.md" holds only the line "MY OWN COMMAND"

  Scenario: The installer's output mentions the file it left alone and the word "skipped"
    Given a project with its own file "commands/bdd-deliver.md" that reads "MY OWN COMMAND"
    When the installer is run on it
    Then the output mentions:
      | bdd-deliver.md |
      | skipped        |
