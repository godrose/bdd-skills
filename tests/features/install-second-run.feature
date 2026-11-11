@install
Feature: A second install keeps the user's config and refreshes the installer's copies

  Running install.sh again updates the commands and leaves the project's config alone.

  Decision (2026-11-11): Each scenario installs into its own project. Why: the old file shared one project across many checks, so a check could pass on what an earlier one left behind.
  Decision (2026-11-11): Messages are checked as the old file checked them, by the text they contain. Why: a migration adds no checks.

  Scenario: A line the user added to the config survives a second install
    Given a project with no .claude folder
    When the installer is run on it
    And the line "SENTINEL" is added to the installed file "bdd-config.md"
    And the installer is run on it
    Then the installed file "bdd-config.md" contains "SENTINEL"

  Scenario: A second install leaves a config the installer made unchanged
    Given a project with no .claude folder
    When the installer is run on it
    And a copy of the installed file "bdd-config.md" is kept
    And the installer is run on it
    Then the installed file "bdd-config.md" is identical to the kept copy

  Scenario: A second install replaces a stale installer copy of the deliver command
    Given a project with no .claude folder
    When the installer is run on it
    And the line "STALE" is added to the installed file "commands/bdd-deliver.md"
    And the installer is run on it
    Then the installed file "commands/bdd-deliver.md" does not contain "STALE"
