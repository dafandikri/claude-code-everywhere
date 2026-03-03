#!/usr/bin/env bash
# Attach to existing tmux session, or create one
SESSION="claude"
if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach-session -t "$SESSION"
else
    exec tmux new-session -s "$SESSION"
fi
