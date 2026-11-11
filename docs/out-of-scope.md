# Out of scope

2026-11-11 | excluded: failing a feature PR that changes the plugin and keeps the version | why: feature PRs never bump the version, only release PRs do | revisit when: the policy changes
2026-11-11 | excluded: checks on the changelog entry and on the marketplace version in the release scenarios | why: other checks cover them, outside this change
2026-11-11 | excluded: new install checks beyond tests/test_install.sh (other commands protected from overwrite, the legacy-file cleanup, the version in the source line) | why: a migration adds no checks | revisit when: the migration series is done
