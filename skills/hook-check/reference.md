# Hook reference

Loaded only when the bundled script's minimal payload is not enough.

## Events

| Event | Fires | Can block? |
|---|---|---|
| `SessionStart` | session begins; `matcher` of `startup`, `resume`, `clear`, `compact` | no |
| `UserPromptSubmit` | user submits a prompt, before Claude sees it | yes, exit 2 discards the prompt |
| `PreToolUse` | before a tool runs; `matcher` is the tool name | yes, exit 2 denies the call |
| `PostToolUse` | after a tool runs; `matcher` is the tool name | no, the tool already ran |
| `Notification` | Claude Code sends a notification | no |
| `Stop` | Claude is about to finish its turn | yes, exit 2 forces it to continue |
| `SubagentStop` | a subagent is about to finish | yes |
| `PreCompact` | before context compaction | no |
| `SessionEnd` | session ends | no |

## Payload fields

Every event carries `session_id`, `transcript_path`, `cwd`, `permission_mode`, and `hook_event_name`.

- `PreToolUse` / `PostToolUse` add `tool_name` and `tool_input`; `PostToolUse` also adds `tool_result` and `tool_use_id`.
  For `Edit` and `Write`, the path is `tool_input.file_path`. For `Bash`, the command is `tool_input.command`.
- `UserPromptSubmit` adds `prompt`.
- `SessionStart` adds `source`.

## Structured output

Print JSON on stdout to say more than an exit code can:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "text Claude sees and can act on"
  },
  "systemMessage": "text shown in the transcript"
}
```

`PreToolUse` additionally accepts `hookSpecificOutput.permissionDecision` of `allow`, `deny`, or `ask`, with `permissionDecisionReason`.
`PostToolUse` has no decision field -- the tool has already run.

## Plugin paths

In a plugin's `hooks/hooks.json`, reference bundled scripts through `${CLAUDE_PLUGIN_ROOT}`; a relative path resolves against the user's working directory, not the plugin, and will break for anyone but you.
`${CLAUDE_PLUGIN_DATA}` is a per-plugin directory that survives updates. `${CLAUDE_PROJECT_DIR}` is the project root.
In shell form (no `args` key) wrap the placeholder in double quotes so spaces in the path survive.
