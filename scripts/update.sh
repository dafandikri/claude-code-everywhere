#!/usr/bin/env bash
set -euo pipefail
echo "Updating Claude Code..."
claude update 2>/dev/null || echo "Claude Code auto-updates natively, skipping."
echo ""
echo "Updating system packages..."
sudo apt-get update -qq && sudo apt-get upgrade -y -qq
echo ""
echo "Done."
