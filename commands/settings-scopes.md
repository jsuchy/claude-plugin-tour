---
description: Show which Claude Code settings are in effect here and which file each one came from.
argument-hint: "[optional: a setting key to focus on, e.g. model]"
allowed-tools: Read, Bash(ls:*), Bash(cat:*), Bash(git rev-parse:*)
---

## Context

- Enterprise managed settings: !`ls -la /Library/Application\ Support/ClaudeCode/managed-settings.json 2>/dev/null || echo "(none)"`
- User settings: !`cat ~/.claude/settings.json 2>/dev/null || echo "(none)"`
- Project settings: !`cat .claude/settings.json 2>/dev/null || echo "(none)"`
- Local settings: !`cat .claude/settings.local.json 2>/dev/null || echo "(none)"`

## Your task

Explain what is actually in effect in this directory, and why.

Precedence, highest first: enterprise managed → command line → `.claude/settings.local.json` → `.claude/settings.json` → `~/.claude/settings.json`.

1. If the user named a setting in `$ARGUMENTS`, answer only for that key: its effective value, the file it came from, and any lower-precedence file it overrode.
2. Otherwise, give a short table of the keys that are set, their effective value, and their source file.
3. Call out anything genuinely worth knowing: the same key set in two files, a `permissions.deny` that a higher-precedence file re-allows, or a hook that will run in this directory that the user may have forgotten about.

Be brief. This is orientation, not an audit. Do not suggest changes unless something is actually in conflict.
