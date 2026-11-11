@install
Feature: A fresh install puts the plugin's files into the project

  install.sh copies the plugin's commands, agent and config into a project's .claude folder.
  This file covers what a user finds there after the first install, and what the installer says.

  Decision (2026-11-11): Each scenario installs into its own project. Why: the old file shared one project across many checks, so a check could pass on what an earlier one left behind.
  Decision (2026-11-11): Messages are checked as the old file checked them, by the text they contain. Why: a migration adds no checks.
  Decision (2026-11-11): A title names only what its steps check. Why: the old file checks that a name or word appears in the output, not that a message is worded a certain way.
  Decision (2026-11-11): The fresh install is split in two files, the files here and the converted text in install-fresh-converted-text.feature. Why: the builder asked for smaller files.

  Scenario: A fresh install puts the main commands, the verifier agent and the config into the project
    Given a project with no .claude folder
    When the installer is run on it
    Then the project has these files in its .claude folder:
      | commands/bdd-design.md    |
      | commands/bdd-implement.md |
      | commands/bdd-run.md       |
      | agents/bdd-verifier.md    |
      | bdd-config.md             |

  Scenario: A fresh install also adds the other commands, the decision schema and a decisions script that can be run
    Given a project with no .claude folder
    When the installer is run on it
    Then the project has these files in its .claude folder:
      | commands/bdd-discover.md     |
      | commands/bdd-triage.md       |
      | commands/bdd-reconcile.md    |
      | commands/bdd-deliver.md      |
      | schemas/decision.schema.json |
    And the file "scripts/decisions.sh" can be run

  Scenario: The installed discover command starts with a source line naming the repo
    Given a project with no .claude folder
    When the installer is run on it
    Then the second line of "commands/bdd-discover.md" is the source line for "https://github.com/godrose/bdd-skills"

  Scenario: The installer's output mentions bdd-deliver.md, merge=union and jq
    Given a project with no .claude folder
    When the installer is run on it
    Then the output mentions:
      | bdd-deliver.md |
      | merge=union    |
      | jq             |

  Scenario: The installed decisions script checks an empty log and exits cleanly
    Given a project with no .claude folder
    When the installer is run on it
    And the installed decisions script is run with "check"
    Then the run passes
    And the output mentions "I-EMPTY"

  Scenario: The installer reads its scripts from the repo root
    Given the installer
    Then it reads its scripts from the scripts folder at the repo root
