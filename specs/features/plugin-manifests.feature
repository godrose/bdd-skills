@plugin-text
Feature: The two manifests name the plugin, pin one version and credit the author

  These scenarios read files and text. They check what the files say and run nothing.

  Decision (2026-11-11): The checks of tests/test_plugin.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): That both manifests exist, the marketplace source and the config template are not written again. Why: layout-manifests-and-folders.feature already covers them.
  Decision (2026-11-11): The version is pinned in both manifests and only release pull requests change it. Why: see Releasing in CLAUDE.md.

  Scenario: The plugin is named bdd
    Given the plugin manifest
    Then its "name" is "bdd"

  Scenario: The plugin version is a semantic version
    Given the plugin manifest
    Then its "version" is a semantic version

  Scenario: The marketplace carries the same version as the plugin
    Given the marketplace file
    Then its "plugins.0.version" is the version of the plugin manifest

  Scenario: The changelog has an entry for the plugin version
    Given the file "CHANGELOG.md"
    Then it has an entry for the version of the plugin manifest

  Scenario: The marketplace has a description
    Given the marketplace file
    Then its "description" is not empty

  Scenario: The marketplace lists the plugin as bdd, in the marketplace gennadyverdel-plugins
    Given the marketplace file
    Then its "plugins.0.name" is "bdd"
    And its "name" is "gennadyverdel-plugins"

  Scenario: The author and the owner are named in full
    Given the plugin manifest
    Then its "author.name" is "Gennady Verdel"
    Given the marketplace file
    Then its "owner.name" is "Gennady Verdel"
