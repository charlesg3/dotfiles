#!/bin/bash
# Records the start time for a Claude session turn, keyed by session_id.
# Paired with stop-notify.sh to compute response duration.
SESSION_ID=$(jq -r '.session_id // "unknown"')
rm -f "/tmp/claude-last-time-${SESSION_ID}"
date +%s > "/tmp/claude-start-${SESSION_ID}"
exit 0
