@skills-text
Feature: Every command and agent has frontmatter, every role has a skill file and no old name is used

  These scenarios read files and text. They check what the files say and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The bdd:feedback check covers every command and agent, as the old loop did. Why: the old check read all of them, not only run and verifier.

  Scenario: Every command and agent opens with frontmatter
    Given the commands and agents of the plugin
    Then every one starts with a frontmatter block and has a description or name line

  Scenario: Every skill role in the template has a skill file
    Given the file "plugin/bdd-config.template.md"
    Then every skill role named in the config template has a command or agent file

  Scenario: No command or agent names bdd:feedback
    Given the commands and agents of the plugin
    Then none of them contains "bdd:feedback"
