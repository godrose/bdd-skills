@install
Feature: A project install keeps the pre-approved tools

  Up to 0.5.0 the plugin's commands carried a list of pre-approved tools. The plugin itself now
  carries none, because the plugin directory refuses them. A project install is not scanned,
  so the installer puts each command's list back.

  Decision (2026-11-11): Each scenario installs into its own project. Why: the old file shared one project across many checks, so a check could pass on what an earlier one left behind.
  Decision (2026-11-11): The check that the plugin's own commands carry no allowed-tools sits here, with tool permissions. Why: the builder approved this placement with the checklist.
  Decision (2026-11-11): The tools are written as a list of names in the Examples. Why: the quotes of the real line would not read well inside a step.

  Scenario Outline: A project install keeps the pre-approved tools of the <command> command
    Given a project with no .claude folder
    When the installer is run on it
    Then the installed <command> command allows exactly "<tools>"
    And the installed <command> command has one allowed-tools line
    And the installed <command> command has its allowed-tools line right after its description

    Examples:
      | command   | tools                                                       |
      | discover  | Agent, Bash, Read, Grep, Glob, AskUserQuestion              |
      | design    | Agent, Bash, Read, Grep, Glob, AskUserQuestion              |
      | implement | Agent, Bash, Read, Write, Edit, Grep, Glob                  |
      | run       | Agent, Bash, Read, Write, Grep, Glob, AskUserQuestion       |
      | triage    | Agent, Bash, Read, Edit, Write, Grep, Glob, AskUserQuestion |
      | reconcile | Bash, Read, Grep, Glob                                      |
      | deliver   | Agent, Bash, Read, Write, Edit, Grep, Glob, AskUserQuestion |

  Scenario Outline: The plugin's own <command> command carries no pre-approved tools
    Given the plugin command "<command>"
    Then it has no allowed-tools line

    Examples:
      | command   |
      | discover  |
      | design    |
      | implement |
      | run       |
      | triage    |
      | reconcile |
      | init      |
      | deliver   |
