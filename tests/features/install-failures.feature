@install
Feature: The installer says what went wrong when it cannot get the plugin files

  Run from a curl pipe, install.sh clones the repo. When the clone fails, or the source has no
  plugin folder, it stops with a message and leaves the project as it was.

  Decision (2026-11-11): These scenarios run a copy of the installer with a stub git. Why: they stay offline.
  Decision (2026-11-11): Messages are checked as the old file checked them, by the text they contain. Why: a migration adds no checks.

  Scenario: A failed clone is reported as a failed clone
    Given a project with no .claude folder
    And an installer whose git fails to clone
    When the installer is run on it
    Then the run fails
    And the output mentions "could not clone"
    And the output does not mention "no plugin/ folder"

  Scenario: A failed clone leaves nothing in the project
    Given a project with no .claude folder
    And an installer whose git fails to clone
    When the installer is run on it
    Then the project has no .claude folder

  Scenario: A source without a plugin folder is reported as that
    Given a project with no .claude folder
    And an installer whose git clones a source with no plugin folder
    When the installer is run on it
    Then the run fails
    And the output mentions "no plugin/ folder"

  Scenario: A source without a plugin folder leaves nothing in the project
    Given a project with no .claude folder
    And an installer whose git clones a source with no plugin folder
    When the installer is run on it
    Then the project has no .claude folder
