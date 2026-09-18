#!/usr/bin/env bash
# Fire a hook command with a synthetic event payload and report what it did.
#
# A hook is just a program that reads JSON on stdin and communicates through
# its exit code and stdout. That means you can run one by hand -- you do not
# need to trigger it from a real session to find out whether it works.
#
# Usage:
#   fire-hook.sh <EventName> [--file PATH] [--command CMD] [--prompt TEXT] -- <hook command...>
#
# Examples:
#   fire-hook.sh Stop -- ./scripts/session-gate.sh
#   fire-hook.sh PostToolUse --file notes.md -- ./hooks/sentence-per-line.sh
#   fire-hook.sh PreToolUse --command "rm -rf /" -- ./hooks/guard.sh
set -uo pipefail

die() { printf 'fire-hook: %s\n' "$1" >&2; exit 64; }

[ $# -ge 1 ] || die "need an event name; see reference.md for the list"
event=$1; shift

file=""; command_str=""; prompt=""
while [ $# -gt 0 ]; do
  case "$1" in
    --file)    file=${2:-};        shift 2 ;;
    --command) command_str=${2:-}; shift 2 ;;
    --prompt)  prompt=${2:-};      shift 2 ;;
    --)        shift; break ;;
    *)         die "unexpected argument '$1' (did you forget -- before the hook command?)" ;;
  esac
done

[ $# -ge 1 ] || die "no hook command given after --"

command -v jq >/dev/null 2>&1 || die "jq is required to build the payload"

# Minimal but structurally faithful payload. Real events carry more fields;
# a hook that depends on a field not here should be fed a fuller one.
payload=$(jq -n \
  --arg event "$event" \
  --arg cwd "$PWD" \
  --arg file "$file" \
  --arg cmd "$command_str" \
  --arg prompt "$prompt" \
  '{
     session_id: "fire-hook-synthetic",
     transcript_path: "/dev/null",
     cwd: $cwd,
     permission_mode: "default",
     hook_event_name: $event
   }
   + (if $file != "" then {tool_name: "Edit", tool_input: {file_path: $file}} else {} end)
   + (if $cmd  != "" then {tool_name: "Bash", tool_input: {command: $cmd}} else {} end)
   + (if $prompt != "" then {prompt: $prompt} else {} end)')

echo "--- payload on stdin"
printf '%s\n' "$payload"

stdout_file=$(mktemp); stderr_file=$(mktemp)
trap 'rm -f "$stdout_file" "$stderr_file"' EXIT

printf '%s' "$payload" | "$@" >"$stdout_file" 2>"$stderr_file"
status=$?

echo "--- exit code: $status"
[ -s "$stdout_file" ] && { echo "--- stdout"; cat "$stdout_file"; }
[ -s "$stderr_file" ] && { echo "--- stderr"; cat "$stderr_file"; }

echo "--- what that means"
case "$status" in
  0)
    if [ -s "$stdout_file" ] && jq -e . >/dev/null 2>&1 <"$stdout_file"; then
      echo "Success, and stdout is valid JSON -- Claude Code will read it as structured output."
      jq -r '
        if .hookSpecificOutput.additionalContext then "  additionalContext: present (Claude sees it as context)" else empty end,
        if .systemMessage or .hookSpecificOutput.systemMessage then "  systemMessage: present (shown in the transcript)" else empty end,
        if .decision then "  decision: \(.decision)" else empty end
      ' <"$stdout_file"
    elif [ -s "$stdout_file" ]; then
      echo "Success, but stdout is NOT JSON. For most events that goes to the debug log only."
      echo "If you meant Claude to see it, print JSON with hookSpecificOutput.additionalContext instead."
    else
      echo "Success, silent. The session continues with nothing added."
    fi
    ;;
  2)
    echo "Blocking. Stderr above is fed back to Claude as the error message."
    [ -s "$stderr_file" ] || echo "  WARNING: exit 2 with empty stderr gives Claude nothing to act on."
    ;;
  *)
    echo "Non-blocking error. The action proceeds; the user sees a hook error notice."
    echo "  If you meant to block, exit 2. If you meant to succeed, exit 0."
    ;;
esac
