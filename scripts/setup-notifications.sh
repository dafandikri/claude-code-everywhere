#!/usr/bin/env bash
set -euo pipefail

# Setup ntfy notifications for Claude Code
# Usage: bash setup-notifications.sh <your-ntfy-topic>
# Example: bash setup-notifications.sh claude-dafandikri

TOPIC="${1:?Usage: bash setup-notifications.sh <your-ntfy-topic>}"
NTFY_URL="ntfy.sh/${TOPIC}"

echo "=== ntfy Notification Setup ==="
echo ""

# Add NTFY_TOPIC to .bashrc
if ! grep -q 'NTFY_TOPIC' ~/.bashrc 2>/dev/null; then
    echo "export NTFY_TOPIC=\"${NTFY_URL}\"" >> ~/.bashrc
    echo "Added NTFY_TOPIC to ~/.bashrc"
fi
export NTFY_TOPIC="${NTFY_URL}"

# Deploy Claude Code hook settings
mkdir -p ~/.claude
if [ -f ~/.claude/settings.json ]; then
    echo "~/.claude/settings.json already exists. Merging hooks..."
    # Use python to merge JSON (available on server)
    # Note: In settings.json, hook events are top-level keys (no "hooks" wrapper)
    python3 -c "
import json
with open('$HOME/.claude/settings.json') as f:
    existing = json.load(f)
existing['Stop'] = [{
    'matcher': '*',
    'hooks': [{
        'type': 'command',
        'command': 'curl -s -d \"Claude Code finished a task\" \${NTFY_TOPIC:-${NTFY_URL}}'
    }]
}]
with open('$HOME/.claude/settings.json', 'w') as f:
    json.dump(existing, f, indent=2)
"
else
    # Note: In settings.json, hook events are top-level keys (no "hooks" wrapper)
    cat > ~/.claude/settings.json << EOF
{
  "Stop": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "curl -s -d \"Claude Code finished a task\" \${NTFY_TOPIC:-${NTFY_URL}}"
        }
      ]
    }
  ]
}
EOF
fi

# Test notification
echo ""
echo "Sending test notification..."
curl -s -d "ntfy setup complete! Notifications working." "${NTFY_URL}"
echo ""
echo "=== Done ==="
echo ""
echo "On your iPhone:"
echo "  1. Install 'ntfy' from the App Store"
echo "  2. Open ntfy → tap '+' → subscribe to topic: ${TOPIC}"
echo "  3. You should see the test notification now!"
echo ""
echo "Claude Code will notify you whenever a task finishes."
