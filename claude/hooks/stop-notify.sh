#!/bin/bash
# Notifies nvim + plays a sound when Claude finishes responding,
# but only if the response took longer than 10 seconds.
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

elapsed=0
start_file="/tmp/claude-start-${SESSION_ID}"
if [ -f "$start_file" ]; then
  start=$(cat "$start_file")
  now=$(date +%s)
  elapsed=$((now - start))
  rm -f "$start_file"
fi

# Save last response time for statusline
if [ "$elapsed" -gt 0 ]; then
  if [ "$elapsed" -ge 60 ]; then
    printf '%dm %ds' $((elapsed / 60)) $((elapsed % 60)) > "/tmp/claude-last-time-${SESSION_ID}"
  else
    printf '%ds' "$elapsed" > "/tmp/claude-last-time-${SESSION_ID}"
  fi
fi

if [ "$elapsed" -gt 150 ]; then
  # Extract first line of Claude's response, truncated to 80 chars
  msg=$(echo "$INPUT" | jq -r '.last_assistant_message // ""' | head -1 | cut -c1-80)
  # Escape backslashes and single quotes for VimL single-quoted string
  msg="${msg//\\/\\\\}"
  msg="${msg//\'/\'\'}"

  if [ -n "$NVIM" ]; then
    nvim --server "$NVIM" --remote-expr "v:lua.notify_done('claude (${elapsed}s)', 0, '${msg}')" &>/dev/null &
  fi
  notification &>/dev/null &
fi
exit 0
