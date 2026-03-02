#!/usr/bin/env bash
set -euo pipefail

# Backup Claude Code config, SSH keys, and convenience scripts
BACKUP_DIR=~/backups
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/claude-dev-backup-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "=== Backing up Claude Code Everywhere config ==="

tar czf "$BACKUP_FILE" \
    -C "$HOME" \
    .tmux.conf \
    .bashrc \
    .ssh/id_ed25519 \
    .ssh/id_ed25519.pub \
    .claude/ \
    bin/ \
    2>/dev/null || true

echo "Backup saved to: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
echo ""
echo "To copy to your Mac:"
echo "  scp dev@YOUR_IP:$BACKUP_FILE ."
echo ""
echo "Keep only last 5 backups..."
ls -t "$BACKUP_DIR"/claude-dev-backup-*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
echo "Done."
