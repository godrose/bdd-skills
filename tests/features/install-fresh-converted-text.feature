@install
Feature: A fresh install converts the plugin text to project names

  The plugin text uses plugin names such as bdd:design and plugin paths. A project install
  uses project names (bdd-design) and .claude paths. This file covers that conversion.

  Decision (2026-11-11): Each scenario installs into its own project. Why: the old file shared one project across many checks, so a check could pass on what an earlier one left behind.
  Decision (2026-11-11): The checks that fit none of the six groups sit where a user meets them: the converted text and the missing init command here, under a fresh install. Why: the builder approved these placements with the checklist.
  Decision (2026-11-11): The converted text is split from the files in install-fresh-files.feature. Why: the builder asked for smaller files.

  Scenario: Installed files carry no plugin paths and no plugin-style skill names
    Given a project with no .claude folder
    When the installer is run on it
    Then no installed command, agent or config mentions "CLAUDE_PLUGIN_ROOT"
    And no installed command, agent or config has a plugin-style skill name

  Scenario: The installed verifier agent is named bdd-verifier
    Given a project with no .claude folder
    When the installer is run on it
    Then the installed file "agents/bdd-verifier.md" contains "name: bdd-verifier"

  Scenario: The installed reconcile command calls the decisions script in the project
    Given a project with no .claude folder
    When the installer is run on it
    Then the installed file "commands/bdd-reconcile.md" contains ".claude/scripts/decisions.sh check"

  Scenario: The installed config names the design command by its project name
    Given a project with no .claude folder
    When the installer is run on it
    Then the installed file "bdd-config.md" contains "`bdd-design`"

  Scenario Outline: The installed <command> command carries no plugin note and no plugin root
    Given a project with no .claude folder
    When the installer is run on it
    Then the installed file "commands/bdd-<command>.md" does not contain "Plugin note"
    And the installed file "commands/bdd-<command>.md" does not contain "plugin root"

    Examples:
      | command   |
      | design    |
      | triage    |
      | reconcile |
      | deliver   |

  Scenario Outline: The installed <command> command says to stop when the config does not exist, and does not say where the template is
    Given a project with no .claude folder
    When the installer is run on it
    Then the installed file "commands/bdd-<command>.md" contains "does not exist, say so and stop"
    And the installed file "commands/bdd-<command>.md" does not contain "template is at"

    Examples:
      | command   |
      | design    |
      | implement |
      | run       |
      | triage    |
      | reconcile |
      | deliver   |

  Scenario: A project install has no init command
    Given a project with no .claude folder
    When the installer is run on it
    Then the project has none of these files in its .claude folder:
      | commands/bdd-init.md |
      | commands/init.md     |
