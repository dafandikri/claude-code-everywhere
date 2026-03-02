#!/usr/bin/env bash
# Attach to existing claude tmux session, or create one
SESSION="claude"
if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach-session -t "$SESSION"
else
    tmux new-session -d -s "$SESSION" -n code
    tmux send-keys -t "$SESSION:code" "claude" Enter
    tmux new-window -t "$SESSION" -n shell
    exec tmux attach-session -t "$SESSION"
fi
