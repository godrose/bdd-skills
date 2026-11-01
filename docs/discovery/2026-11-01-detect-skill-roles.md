# Discovery: skill roles in `/bdd:init --detect`

## Story

`--detect` fills the Tooling and Conventions placeholders. The Skill Roles table also has two placeholders, `domain-knowledge` and `requirements-sync`. A project that adopted BDD usually already has its own skills for them in `.claude/commands/`, such as `bdd-<project>-knowledge` or `*-sync`. `--detect` sees them and proposes nothing.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Propose, list or leave? | Propose a match per role, with evidence and confidence, approved row by row | Same model as the other rows. A wrong guess costs nothing, because nothing is written until approved. |
| 2 | How to find candidates? | Name and one-line description in each skill header, in `.claude/commands/` and `.claude/skills/`. Name hints raise confidence. | The description is how a skill says what it is for. Bodies and user-level skills are more than a proposal needs. |
| 3 | Several plausible skills for one role? | Propose the best one at medium or low confidence, name the runners-up in the evidence | The table holds one skill per role. The runners-up stay visible so the user can switch. |
| 4 | No candidate? | Leave the row alone, say so, name the places searched | Follows the existing `unknown` rule. Blanking a row needs the commands to read `none`, which none do today. |

## Calls made by the designer

- A row that already has a value is never changed.
- The installer's own files (`bdd-design` and the rest, told apart by the `# Source:` header) are never candidates.
- Only the project's `.claude/commands/` and `.claude/skills/` are searched. User-level skills and skills from other plugins are out of scope.
- Only `domain-knowledge` and `requirements-sync`. The plugin's own roles already have values.

## Spec points

- **Existing users:** a config that already names real skills is untouched. Their own `bdd-*` skills stay.
- **First run:** a fresh config gets the role proposals next to the Tooling and Conventions ones.
- **Exclusions:** plugin only. Read-only until approved. No skeleton skills are created. No change to how commands read an empty role.
