#!/usr/bin/env bash
set -euo pipefail

# Claude Code Everywhere — Sync Claude Code config to this machine
# Run as the dev user on the droplet:
#   bash ~/claude-code-everywhere/scripts/setup-claude-config.sh
#
# What this does:
#   1. Installs all plugins matching your local Mac setup
#   2. Copies settings.json (plugins, HUD, spinner verbs, ntfy hook)
#   3. Copies global CLAUDE.md

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Claude Code Config Setup ==="
echo ""

# --- 1. Install plugins ---
echo "[1/3] Installing plugins..."
echo "  (This may take a few minutes — each plugin downloads from GitHub)"
echo ""

plugins=(
  "superpowers@claude-plugins-official"
  "frontend-design@claude-plugins-official"
  "typescript-lsp@claude-plugins-official"
  "security-guidance@claude-plugins-official"
  "linear@claude-plugins-official"
  "context7@claude-plugins-official"
  "feature-dev@claude-plugins-official"
  "figma@claude-plugins-official"
  "claude-md-management@claude-plugins-official"
  "code-simplifier@claude-plugins-official"
  "gitlab@claude-plugins-official"
  "code-review@claude-plugins-official"
  "github@claude-plugins-official"
  "ralph-loop@claude-plugins-official"
  "playwright@claude-plugins-official"
  "commit-commands@claude-plugins-official"
  "serena@claude-plugins-official"
  "pr-review-toolkit@claude-plugins-official"
  "claude-code-setup@claude-plugins-official"
  "explanatory-output-style@claude-plugins-official"
  "pyright-lsp@claude-plugins-official"
  "greptile@claude-plugins-official"
  "vercel@claude-plugins-official"
  "learning-output-style@claude-plugins-official"
  "semgrep@claude-plugins-official"
)

for plugin in "${plugins[@]}"; do
  if claude plugin list 2>/dev/null | grep -q "${plugin%%@*}"; then
    echo "  ✓ $plugin (already installed)"
  else
    echo "  Installing $plugin..."
    claude plugin install "$plugin" --yes 2>/dev/null && echo "  ✓ $plugin" || echo "  ✗ $plugin (failed, skipping)"
  fi
done

# Install claude-hud from its own marketplace
echo "  Installing claude-hud@claude-hud..."
claude plugin install "claude-hud@claude-hud" --yes 2>/dev/null && echo "  ✓ claude-hud" || echo "  ✗ claude-hud (failed, skipping)"

echo ""

# --- 2. Apply settings.json ---
echo "[2/3] Applying settings.json..."
mkdir -p ~/.claude
cp "$REPO_DIR/config/claude-settings.json" ~/.claude/settings.json
echo "  ✓ ~/.claude/settings.json"

# --- 3. Copy global CLAUDE.md ---
echo "[3/3] Copying global CLAUDE.md..."
cp "$REPO_DIR/config/CLAUDE.md" ~/.claude/CLAUDE.md
echo "  ✓ ~/.claude/CLAUDE.md"

echo ""
echo "=== Done ==="
echo ""
echo "Restart Claude Code for changes to take effect:"
echo "  claude"
