#!/usr/bin/env bash
# PostToolUse: after Claude edits a Markdown file, mention sentences that share a line.
#
# Advisory by design. It always exits 0 and never blocks an edit -- it returns
# additionalContext, which Claude can see and act on. That is the difference
# between a hook that helps and a hook that fights you.
#
# Requires jq. Does nothing at all if jq is missing, the file is not Markdown,
# or the file is gone.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input" 2>/dev/null) || exit 0

case "$file" in
  *.md|*.markdown) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

# A line holding a sentence end followed by another capitalised sentence.
# Skips fenced code and tables, which legitimately pack a lot onto one line.
offenders=$(awk '
  /^```/ { infence = !infence; next }
  infence { next }
  /^[[:space:]]*\|/ { next }
  /[.!?]["\x27)]?[[:space:]]+[A-Z]/ { print NR }
' "$file" | head -20)

[ -n "$offenders" ] || exit 0

count=$(wc -l <<<"$offenders" | tr -d ' ')
lines=$(tr '\n' ',' <<<"$offenders" | sed 's/,$//')

jq -n --arg file "$file" --arg lines "$lines" --arg count "$count" '
  {
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("\($file): \($count) line(s) appear to hold more than one sentence (lines \($lines)). " +
        "This repo writes one sentence per line so diffs stay readable. Split them unless the line is a heading, a link, or quoted text.")
    }
  }'
exit 0
