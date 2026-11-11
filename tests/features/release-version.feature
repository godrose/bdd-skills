Feature: A release raises the plugin version

  A pull request whose title starts with "release:" is held to two checks. The version
  must be higher than on main, and a change to the plugin must come with a new version.
  The cache is keyed by version, so a change without a new version never reaches users.

  Decision (2026-11-11): Only release pull requests are held to these checks. Why: feature pull requests never bump the version, and CI runs the release check only for a title that starts with "release:".
  Decision (2026-11-11): The scenarios assert the exit status only, like the old checks. Why: message checks are a later follow-up.
  Decision (2026-11-11): Each check is run on its own, as the old bash test ran them. Why: run together, a same-version release fails the "version is higher" check too, so a broken "plugin changed" check went unseen.

  Scenario: A release that raises the version passes the "version is higher" check
    Given a main where the plugin has version "0.4.0"
    And a release branch that sets the version to "0.4.1"
    When the "version is higher" check is run
    Then the run passes

  Scenario: A release that keeps the same version fails the "version is higher" check
    Given a main where the plugin has version "0.4.0"
    And a release branch that sets the version to "0.4.0"
    When the "version is higher" check is run
    Then the run fails

  Scenario: A release that lowers the version fails the "version is higher" check
    Given a main where the plugin has version "0.4.0"
    And a release branch that sets the version to "0.3.0"
    When the "version is higher" check is run
    Then the run fails

  Scenario: Versions are compared as numbers, not as text
    Given a main where the plugin has version "0.4.9"
    And a release branch that sets the version to "0.4.10"
    When the "version is higher" check is run
    Then the run passes

  Scenario: A release that changes the plugin without raising the version fails both checks
    Given a main where the plugin has version "0.4.0"
    And a release branch that changes a plugin command and sets the version to "0.4.0"
    When the "plugin changed" check is run
    Then the run fails
    When the "version is higher" check is run
    Then the run fails

  Scenario: A release that changes the plugin and raises the version passes both checks
    Given a main where the plugin has version "0.4.0"
    And a release branch that changes a plugin command and sets the version to "0.4.1"
    When the "plugin changed" check is run
    Then the run passes
    When the "version is higher" check is run
    Then the run passes

  Scenario: The first release passes both checks, because main has no version yet
    Given a main where the plugin has no version
    And a release branch that changes a plugin command and sets the version to "0.4.0"
    When the "plugin changed" check is run
    Then the run passes
    When the "version is higher" check is run
    Then the run passes

  Scenario: A plugin moved in from the old repo root keeps the same version and fails the "version is higher" check
    Given a main where the plugin sits at the old repo root with version "0.4.0"
    And a release branch that moves the plugin into the plugin folder and sets the version to "0.4.0"
    When the "version is higher" check is run
    Then the run fails

  Scenario: A plugin moved in from the old repo root with a raised version passes both checks
    Given a main where the plugin sits at the old repo root with version "0.4.0"
    And a release branch that moves the plugin into the plugin folder and sets the version to "0.5.0"
    When the "plugin changed" check is run
    Then the run passes
    When the "version is higher" check is run
    Then the run passes
