# Plugin Tour

A deliberately small Claude Code plugin: **one command, one skill, one agent, one hook.**
It exists to be read. Every component is the smallest honest example of its kind, and each one does something real.

If you are trying to understand what a plugin is, clone it and read it end to end — it is about 300 lines.

## Install

```sh
claude plugin marketplace add jsuchy/claude-plugin-tour
claude plugin install plugin-tour@jsuchy
```

Or, without installing anything, point a session at a local clone:

```sh
claude --plugin-dir ~/Projects/claude-plugin-tour
```

Remove it with `claude plugin uninstall plugin-tour@jsuchy`.

## What's in it, and what each one teaches

| Component | File | The point |
|---|---|---|
| Command | `commands/settings-scopes.md` | A command is **just a prompt in a Markdown file**. No code. `!`-prefixed lines run shell and inject the output; `$ARGUMENTS` carries what the user typed. |
| Skill | `skills/hook-check/` | A skill is a prompt Claude **chooses** to load, on the strength of its `description`. It can bundle scripts and reference files that load only when needed. |
| Agent | `agents/setup-reviewer.md` | An agent is a **separate context** with its own tool allowlist and model. Use one when you want work done without its intermediate output filling your session. |
| Hook | `hooks/hooks.json` + `hooks/sentence-per-line.sh` | A hook is **deterministic**. It runs whether or not Claude feels like it, because the harness runs it, not the model. |

### Command vs. skill — the distinction people trip on

Both are Markdown. The difference is *who decides*.

A **command** runs because the user typed `/settings-scopes`. It is always a deliberate act.
A **skill** loads because Claude read its `description` and judged it relevant. You are writing for a reader who has to decide, which is why skill descriptions say when *not* to use them.

### Why the hook is advisory

`hooks/sentence-per-line.sh` always exits 0 and returns `additionalContext` rather than blocking.
That is a choice, and it is the one most people get wrong first. A hook that blocks on a heuristic will fight you for the rest of the day. Reserve exit 2 for things you are certain about.

Exit codes are the whole interface:

- `0` — success; JSON on stdout is read as structured output
- `2` — blocking; stderr is fed back to Claude as the error
- anything else — non-blocking error; the action proceeds and the user sees an error notice

The last row is the trap. A script with `set -e` that dies for an unrelated reason exits `1`, not `2` — so a gate you believed was strict **fails open, silently**. Test for it:

```sh
skills/hook-check/scripts/fire-hook.sh Stop -- ./your-hook.sh
```

That script is the plugin's own skill, and you can run it directly. A hook is an ordinary program that reads JSON on stdin; nothing about testing one requires a live session.

## What a plugin cannot do

This matters more than the feature list, because it decides whether a plugin is the right tool at all.

A plugin **can** ship: commands, skills, agents, hooks, MCP servers, LSP servers, `bin/` executables, output styles, and (experimentally) themes and monitors.

A plugin **cannot** ship:

- **`CLAUDE.md` or any memory.** Project context does not load from a plugin. If what you want to distribute is knowledge, you want a repo, not a plugin.
- **`permissions`.** Allow/deny rules are settings, at user, project, or local scope.
- **`model`, `modelSettings`, `permissions.defaultMode`, statusline.** All settings.

So the usual instinct — "I'll put my whole Claude setup in a plugin and install it on a new machine" — only ever covers half of it. The settings half needs a dotfile manager, or copy and paste. Know which half you are solving before you start.

## One more trap, from the field

If a dotfile manager writes your `~/.claude/settings.json`, decide deliberately whether `enabledPlugins` is managed from source.
Managed, it is authoritative: enabling or disabling a plugin on one machine gets reverted on the next apply, and it will look like the plugin is broken. Unmanaged, plugin enablement stays a per-machine decision, at the cost that a fresh machine starts with nothing enabled.

Neither is wrong. Picking by accident is.

## Status

Version 0.1.0. A teaching artifact, maintained only as long as it is useful for that.
Copy anything here into your own plugin; that is what it is for.

MIT licensed.
