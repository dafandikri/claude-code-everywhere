#!/usr/bin/env bash
set -euo pipefail

# Restore Claude Code config from backup
BACKUP_FILE="${1:?Usage: bash restore.sh <backup-file.tar.gz>}"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: File not found: $BACKUP_FILE"
    exit 1
fi

echo "=== Restoring from: $BACKUP_FILE ==="
echo ""
echo "This will overwrite: ~/.tmux.conf, ~/.bashrc, ~/.ssh/keys, ~/.claude/, ~/bin/"
read -p "Continue? [y/N] " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 0
fi

tar xzf "$BACKUP_FILE" -C "$HOME"
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 700 ~/.ssh

echo ""
echo "Restored. Restart your tmux session:"
echo "  tmux kill-server && start-claude.sh"
