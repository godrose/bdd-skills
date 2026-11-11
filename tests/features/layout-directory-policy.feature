@layout
Feature: The plugin folder meets the directory's file-type and tool policy

  The directory refuses a plugin from an organization that is not Verified if it holds a
  disallowed file type, a script, a package-manager file, or a command that pre-approves
  tools beyond the read tools.

  Decision (2026-11-11): The file-type, shebang and package-manager scenarios read tracked files only, and the tool scenario reads only quoted values. Why: the old checks did, and a migration adds no checks.
  Decision (2026-11-11): The docs-index pointers and the "earlier layout" line sit in this feature. Why: the maintainer groups had no home for them.

  Scenario: Only the file types the directory allows are in the plugin folder
    Given the files tracked in the plugin folder
    Then every one is Markdown, text, JSON, YAML, PNG, JPEG, GIF, WebP or ICO, or is a LICENSE or .gitignore file

  Scenario: No file in the plugin folder starts with a shebang
    Given the files tracked in the plugin folder
    Then none of them starts with "#!"

  Scenario: No package-manager file is in the plugin folder
    Given the files tracked in the plugin folder
    Then none of them is a package-manager file

  Scenario: No command or agent pre-approves tools beyond Read, Grep, Glob and LS
    Given the commands and agents of the plugin
    Then none of them pre-approves a tool beyond Read, Grep, Glob and LS

  Scenario: The docs index points to the directory policy
    Given the docs index
    Then it contains "directory-policy.md"

  Scenario: The contributor guide says that the directory refuses
    Given the contributor guide
    Then it contains "refuses"

  Scenario: The docs index says the older packs follow the earlier layout
    Given the docs index
    Then it contains "earlier layout"
