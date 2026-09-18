---
name: hook-check
description: >
  Test a Claude Code hook by running it directly with a synthetic event payload, and explain what its exit code and
  output actually do. Use when writing a new hook, when a hook is not firing or not blocking as expected, or when
  someone asks what a hook's exit code means. Not for configuring where a hook is registered -- that is a settings
  question. Not for MCP servers or skills.
allowed-tools: Bash, Read, Glob
---

# Checking a hook

A hook is an ordinary program. Claude Code writes JSON to its stdin, then reads its exit code and stdout.
Nothing about that requires a live session, so test hooks by running them.

## Steps

1. **Find the hook.** It is registered in `~/.claude/settings.json`, `.claude/settings.json`, `.claude/settings.local.json`, or a plugin's `hooks/hooks.json`. Read the registration, not just the script -- a hook that works but is registered under the wrong `matcher` never runs.

2. **Fire it.** Use the bundled script:

   ```
   scripts/fire-hook.sh <EventName> [--file PATH] [--command CMD] [--prompt TEXT] -- <hook command...>
   ```

   For example: `scripts/fire-hook.sh Stop -- ./scripts/session-gate.sh`

   It prints the payload it sent, the exit code, both output streams, and an interpretation.

3. **Check the exit code against intent.** This is where most hooks are wrong:

   - `0` -- success. Stdout is read as JSON if it looks like JSON, otherwise it goes to the debug log for most events.
   - `2` -- blocking. Stderr is fed back to Claude as the error. An exit 2 with empty stderr tells Claude nothing.
   - anything else -- non-blocking error. The action proceeds and the user sees an error notice. This is the accidental case: a script with `set -e` that dies on an unrelated command exits 1, not 2, so it fails *open*.

4. **Report** what fires, what it returns, and whether that matches what the author meant. If the hook is meant to gate something, say plainly whether it actually gates it.

## When the payload is not enough

The script sends a minimal, structurally faithful event. Real events carry more fields.
If the hook reads a field the script does not send, read `reference.md` for the full event list and field names, then hand-build a payload and pipe it in directly.

## Do not

Do not "fix" a hook by loosening it until it passes. A hook that exits 0 unconditionally is not a working hook.
