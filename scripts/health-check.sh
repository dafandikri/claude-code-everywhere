#!/usr/bin/env bash
set -uo pipefail

# Claude Code Everywhere — Health Check
# Verifies all components are installed and working

PASS=0
FAIL=0

check() {
    local name="$1"
    local cmd="$2"
    if eval "$cmd" &>/dev/null; then
        echo "  ✓ $name"
        ((PASS++))
    else
        echo "  ✗ $name"
        ((FAIL++))
    fi
}

echo "=== Claude Code Everywhere — Health Check ==="
echo ""

echo "Core:"
check "Claude Code installed" "command -v claude"
check "Node.js 22+" "node --version | grep -q 'v2[2-9]'"
check "Python 3" "command -v python3"
check "Docker" "command -v docker && docker info"
check "Git" "command -v git"
check "tmux" "command -v tmux"
check "mosh" "command -v mosh-server"

echo ""
echo "CLI Tools:"
check "gh (GitHub CLI)" "command -v gh"
check "glab (GitLab CLI)" "command -v glab"
check "jq" "command -v jq"
check "ripgrep" "command -v rg"

echo ""
echo "Security:"
check "UFW active" "sudo ufw status | grep -q 'Status: active'"
check "fail2ban running" "systemctl is-active fail2ban"
check "SSH key exists" "test -f ~/.ssh/id_ed25519"

echo ""
echo "Auth:"
check "gh authenticated" "gh auth status"
check "glab authenticated" "glab auth status"

echo ""
echo "Config:"
check "tmux config exists" "test -f ~/.tmux.conf"
check "Claude Code config exists" "test -d ~/.claude"
check "start-claude.sh exists" "test -x ~/bin/start-claude.sh"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
