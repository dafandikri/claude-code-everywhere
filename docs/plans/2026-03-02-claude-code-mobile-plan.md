# Claude Code Mobile — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a fully automated setup for running Claude Code CLI on an iPhone via SSH to a DigitalOcean droplet, using Termius + mosh + tmux.

**Architecture:** iPhone runs Termius (mosh client) → connects to DigitalOcean droplet (Ubuntu 24.04) → attaches to persistent tmux session → Claude Code CLI runs inside tmux. Setup is automated via a single `setup.sh` script. Guides cover DigitalOcean provisioning and Termius iPhone configuration.

**Tech Stack:** Bash, Ubuntu 24.04, mosh, tmux, Claude Code CLI (native installer), UFW, fail2ban, DigitalOcean

---

## Project Structure

```
claude-code-everywhere/
├── CLAUDE.md                           # Claude Code guidance for this repo
├── Makefile                            # Common operations (setup, health, backup)
├── LICENSE                             # MIT
├── .gitignore                          # Excludes .env.local, keys, OS files
├── .env.example                        # Configurable values template
├── docs/
│   ├── plans/                          # Design doc + implementation plan
│   ├── DIGITALOCEAN-SETUP.md           # Droplet creation + sync guide
│   ├── TERMIUS-SETUP.md                # iPhone Termius config guide
│   ├── LINEAR-SETUP.md                 # Linear MCP integration guide
│   └── GITLAB-SETUP.md                 # GitLab setup for team projects
├── scripts/
│   ├── setup.sh                        # Main server setup (run as root)
│   ├── setup-notifications.sh          # ntfy push notification setup
│   ├── health-check.sh                 # Verify all components working
│   ├── backup.sh                       # Backup server config
│   ├── restore.sh                      # Restore from backup
│   ├── start-claude.sh                 # Start/attach tmux + claude
│   └── update.sh                       # Update Claude Code + system
├── config/
│   ├── tmux.conf                       # tmux configuration
│   ├── 99-hardened.conf                # SSH hardening (sshd_config.d drop-in)
│   ├── jail.local                      # fail2ban SSH jail config
│   ├── claude-settings.json            # Claude Code hooks (ntfy notifications)
│   └── mcp.json                        # MCP servers (Linear + GitLab)
└── README.md                           # Project overview + quickstart
```

## Sync & Submission

The droplet has its own GitHub SSH key + `gh` CLI. It can independently:
- `git push` commits to GitHub
- `gh pr create` pull requests
- `gh pr merge` PRs
- `gh issue create` issues

Claude Code can do all of these via its built-in tools during a session.

To sync back to your Mac: `git pull origin main`. Git is the sync layer.

---

### Task 1: Initialize git repo and project structure

**Files:**
- Create: `README.md`
- Create: `scripts/` directory
- Create: `config/` directory

**Step 1: Initialize git repo**

```bash
cd ~/Documents/Personal/claude-code-everywhere
git init
```

**Step 2: Create directory structure**

```bash
mkdir -p scripts config docs
```

**Step 3: Create README.md**

Write `README.md` with:

```markdown
# Claude Code Everywhere

Run Claude Code CLI from your iPhone using Termius + mosh + tmux on a DigitalOcean droplet.

## Quickstart

1. Create a DigitalOcean droplet — see [docs/DIGITALOCEAN-SETUP.md](docs/DIGITALOCEAN-SETUP.md)
2. Run the setup script on your droplet:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/YOUR_USER/claude-code-everywhere/main/scripts/setup.sh | bash -s YOUR_SSH_PUBLIC_KEY
   ```
   Or clone and run locally:
   ```bash
   git clone https://github.com/YOUR_USER/claude-code-everywhere.git
   cd claude-code-everywhere
   sudo bash scripts/setup.sh "$(cat ~/.ssh/id_ed25519.pub)"
   ```
3. Configure Termius on your iPhone — see [docs/TERMIUS-SETUP.md](docs/TERMIUS-SETUP.md)
4. Connect and run `claude`

## What This Sets Up

- **mosh** — mobile shell that survives network switches and phone sleep
- **tmux** — persistent terminal sessions that keep Claude Code running
- **Claude Code CLI** — native installer with auto-updates
- **Security** — SSH key-only auth, UFW firewall, fail2ban, auto security updates
- **Convenience scripts** — `start-claude.sh` (one-command session attach) and `update.sh`

## Requirements

- DigitalOcean account (GitHub Student Pack gives $200 credit)
- Claude Pro, Max, Teams, or Enterprise subscription
- iPhone with Termius app (free tier works)

## Cost

$0/month for server (covered by GitHub Student Pack for 12+ months).
$20/month for Claude Pro (existing subscription).
```

**Step 4: Commit**

```bash
git add README.md scripts config docs
git commit -m "chore: initialize project structure"
```

---

### Task 2: Create tmux configuration

**Files:**
- Create: `config/tmux.conf`

**Step 1: Write tmux.conf**

Write `config/tmux.conf`:

```bash
# Claude Code Everywhere — tmux config
# Optimized for mobile SSH via Termius on iPhone

# --- General ---
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
set -s escape-time 10          # Low delay for responsive mobile typing
set -g history-limit 10000     # Scrollback buffer (10k lines)
set -g base-index 1            # Start windows at 1 (easier on phone keyboard)
setw -g pane-base-index 1      # Start panes at 1

# --- Mouse support (critical for Termius scrolling) ---
set -g mouse on

# --- Status bar ---
set -g status-position bottom
set -g status-style "bg=colour235,fg=colour248"
set -g status-left " #S "
set -g status-left-style "bg=colour25,fg=colour255,bold"
set -g status-right " %H:%M "
set -g status-right-style "bg=colour235,fg=colour248"

# Window status
setw -g window-status-format " #I:#W "
setw -g window-status-current-format " #I:#W "
setw -g window-status-current-style "bg=colour25,fg=colour255,bold"

# --- Auto-rename windows based on running command ---
setw -g automatic-rename on

# --- Renumber windows when one is closed ---
set -g renumber-windows on

# --- Activity monitoring ---
setw -g monitor-activity on
set -g visual-activity off
```

**Step 2: Commit**

```bash
git add config/tmux.conf
git commit -m "feat: add tmux config optimized for mobile SSH"
```

---

### Task 3: Create SSH hardening config

**Files:**
- Create: `config/99-hardened.conf`

**Step 1: Write SSH hardening drop-in config**

Write `config/99-hardened.conf`:

```bash
# SSH hardening — drop into /etc/ssh/sshd_config.d/
# Disables password auth, root login, and other weak defaults

PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

**Step 2: Commit**

```bash
git add config/99-hardened.conf
git commit -m "feat: add SSH hardening config"
```

---

### Task 4: Create fail2ban jail config

**Files:**
- Create: `config/jail.local`

**Step 1: Write fail2ban jail config**

Write `config/jail.local`:

```ini
# fail2ban jail — drop into /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
```

**Step 2: Commit**

```bash
git add config/jail.local
git commit -m "feat: add fail2ban SSH jail config"
```

---

### Task 5: Create the main setup.sh script

**Files:**
- Create: `scripts/setup.sh`

**Step 1: Write setup.sh**

Write `scripts/setup.sh`. This script is run as root on a fresh Ubuntu 24.04 droplet. It takes one argument: the user's SSH public key.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Claude Code Everywhere — Server Setup
# Usage: sudo bash setup.sh "ssh-ed25519 AAAA... user@host"

SSH_PUBLIC_KEY="${1:?Usage: sudo bash setup.sh \"your-ssh-public-key\"}"
USERNAME="dev"

echo "=== Claude Code Everywhere Setup ==="
echo ""

# --- 0. Swap space (essential for 2GB droplets) ---
echo "[1/12] Configuring 2GB swap space..."
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "  Swap enabled."
else
    echo "  Swap already exists, skipping."
fi

# --- 1. System updates ---
echo "[2/12] Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

# Set timezone to Asia/Jakarta
timedatectl set-timezone Asia/Jakarta

# --- 2. Install required packages ---
echo "[3/12] Installing core packages..."
apt-get install -y -qq \
  mosh tmux fail2ban git curl ufw unattended-upgrades \
  build-essential gcc make \
  python3 python3-pip python3-venv \
  postgresql-client \
  jq ripgrep htop wget zip unzip ca-certificates gnupg lsb-release

# Install GitHub CLI (gh)
(type -p wget >/dev/null || apt-get install -y -qq wget) \
  && mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat "$out" | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt-get update -qq \
  && apt-get install -y -qq gh

# Install GitLab CLI (glab)
curl -sSL "https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository" | bash
apt-get install -y -qq glab

# Install Docker
echo "[4/12] Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

# --- 3. Create non-root user ---
echo "[5/12] Creating user '$USERNAME'..."
if id "$USERNAME" &>/dev/null; then
    echo "  User '$USERNAME' already exists, skipping creation."
else
    adduser --disabled-password --gecos "" "$USERNAME"
fi

# Set up SSH key for the new user
mkdir -p /home/$USERNAME/.ssh
echo "$SSH_PUBLIC_KEY" > /home/$USERNAME/.ssh/authorized_keys
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

# Add user to sudo and docker groups
usermod -aG sudo "$USERNAME"
usermod -aG docker "$USERNAME"
# Allow passwordless sudo for convenience (optional but helpful for mobile)
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
chmod 440 /etc/sudoers.d/$USERNAME

# --- 4. SSH hardening ---
echo "[6/12] Hardening SSH..."
cat > /etc/ssh/sshd_config.d/99-hardened.conf << 'SSHEOF'
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
SSHEOF
systemctl restart sshd

# --- 5. Firewall ---
echo "[7/12] Configuring UFW firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp        # SSH
ufw allow 60000:61000/udp  # mosh
ufw --force enable

# --- 6. fail2ban ---
echo "[8/12] Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << 'F2BEOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
F2BEOF
systemctl enable fail2ban
systemctl restart fail2ban

# --- 7. Automatic security updates ---
echo "[9/12] Enabling automatic security updates..."
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'APTEOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APTEOF

# --- 8. Install Claude Code + tmux config (as the dev user) ---
echo "[10/12] Installing Claude Code, dev tools, and configuring tmux..."
sudo -u "$USERNAME" bash << 'USEREOF'
set -euo pipefail

# Install Claude Code (native installer)
curl -fsSL https://claude.ai/install.sh | bash

# Deploy tmux config
cat > ~/.tmux.conf << 'TMUXEOF'
# Claude Code Everywhere — tmux config
# Optimized for mobile SSH via Termius on iPhone
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
set -s escape-time 10
set -g history-limit 10000
set -g base-index 1
setw -g pane-base-index 1
set -g mouse on
set -g status-position bottom
set -g status-style "bg=colour235,fg=colour248"
set -g status-left " #S "
set -g status-left-style "bg=colour25,fg=colour255,bold"
set -g status-right " %H:%M "
set -g status-right-style "bg=colour235,fg=colour248"
setw -g window-status-format " #I:#W "
setw -g window-status-current-format " #I:#W "
setw -g window-status-current-style "bg=colour25,fg=colour255,bold"
setw -g automatic-rename on
set -g renumber-windows on
setw -g monitor-activity on
set -g visual-activity off
TMUXEOF

# Generate GitHub SSH key for this server
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "claude-dev-droplet" -f ~/.ssh/id_ed25519 -N ""
fi

# Install Python data science / academic packages
python3 -m pip install --user --break-system-packages \
  pandas numpy scikit-learn matplotlib seaborn \
  jupyter notebook \
  requests flask fastapi uvicorn

# Create ~/bin for convenience scripts
mkdir -p ~/bin

# Create start-claude.sh
cat > ~/bin/start-claude.sh << 'STARTEOF'
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
STARTEOF
chmod +x ~/bin/start-claude.sh

# Create update.sh
cat > ~/bin/update.sh << 'UPDATEEOF'
#!/usr/bin/env bash
set -euo pipefail
echo "Updating Claude Code..."
claude update 2>/dev/null || echo "Claude Code auto-updates natively, skipping."
echo ""
echo "Updating system packages..."
sudo apt-get update -qq && sudo apt-get upgrade -y -qq
echo ""
echo "Done."
UPDATEEOF
chmod +x ~/bin/update.sh

# Add ~/bin to PATH in .bashrc if not already there
if ! grep -q 'export PATH="$HOME/bin:$PATH"' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
fi

# Auto-attach tmux on SSH login (append to .bashrc)
cat >> ~/.bashrc << 'RCEOF'

# Auto-attach to tmux claude session on SSH login
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then
    ~/bin/start-claude.sh
fi
RCEOF

USEREOF

# --- 11. Git config ---
echo "[11/12] Configuring git identity..."
sudo -u "$USERNAME" git config --global init.defaultBranch main

# --- 12. Final summary ---
echo "[12/12] Verifying installation..."
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Your server is ready. Connect from Termius with:"
echo "  mosh dev@$(curl -s ifconfig.me)"
echo ""
echo "=== NEXT STEPS (do these once after connecting as dev) ==="
echo ""
echo "1. Authenticate Claude Code:"
echo "   claude"
echo ""
echo "2. Add this server's SSH key to GitHub (for git push/PRs):"
sudo -u "$USERNAME" cat /home/$USERNAME/.ssh/id_ed25519.pub
echo ""
echo "   → Go to github.com → Settings → SSH Keys → Add this key"
echo ""
echo "3. Set your git identity:"
echo "   git config --global user.name \"Your Name\""
echo "   git config --global user.email \"your-email@example.com\""
echo ""
echo "4. Authenticate GitHub CLI (for creating PRs from server):"
echo "   gh auth login"
echo ""
echo "Convenience commands:"
echo "  start-claude.sh  — Start/attach Claude Code tmux session"
echo "  update.sh         — Update Claude Code + system packages"
```

**Step 2: Make executable**

```bash
chmod +x scripts/setup.sh
```

**Step 3: Commit**

```bash
git add scripts/setup.sh
git commit -m "feat: add main server setup script"
```

---

### Task 6: Create convenience scripts (standalone copies)

**Files:**
- Create: `scripts/start-claude.sh`
- Create: `scripts/update.sh`

These are standalone copies of the scripts embedded in setup.sh, kept in the repo for reference and independent use.

**Step 1: Write start-claude.sh**

Write `scripts/start-claude.sh`:

```bash
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
```

**Step 2: Write update.sh**

Write `scripts/update.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "Updating Claude Code..."
claude update 2>/dev/null || echo "Claude Code auto-updates natively, skipping."
echo ""
echo "Updating system packages..."
sudo apt-get update -qq && sudo apt-get upgrade -y -qq
echo ""
echo "Done."
```

**Step 3: Make both executable and commit**

```bash
chmod +x scripts/start-claude.sh scripts/update.sh
git add scripts/start-claude.sh scripts/update.sh
git commit -m "feat: add convenience scripts (start-claude, update)"
```

---

### Task 7: Write DigitalOcean setup guide

**Files:**
- Create: `docs/DIGITALOCEAN-SETUP.md`

**Step 1: Write the guide**

Write `docs/DIGITALOCEAN-SETUP.md`:

```markdown
# DigitalOcean Droplet Setup Guide

## Prerequisites

- GitHub Student Developer Pack (for $200 DigitalOcean credit)
- An SSH key pair on your local machine

## Step 1: Claim DigitalOcean Credits

1. Go to [education.github.com/pack](https://education.github.com/pack)
2. Find **DigitalOcean** in the partner list
3. Click to claim your $200 credit
4. Create a DigitalOcean account using the provided link
5. Verify credits are applied: DigitalOcean dashboard → Billing → Credits

## Step 2: Generate SSH Key (if you don't have one)

On your computer (or in Termius on iPhone):

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

Copy the public key:
```bash
cat ~/.ssh/id_ed25519.pub
```

## Step 3: Add SSH Key to DigitalOcean

1. Go to DigitalOcean dashboard → Settings → Security → SSH Keys
2. Click "Add SSH Key"
3. Paste your public key and give it a name

## Step 4: Create Droplet

1. Click "Create" → "Droplets"
2. Configure:
   - **Region:** Choose closest to you (e.g., Singapore `sgp1`)
   - **Image:** Ubuntu 24.04 LTS
   - **Size:** Regular → $12/mo (2 GB RAM / 1 vCPU / 50 GB SSD)
   - **Authentication:** SSH Key (select the key you added)
   - **Hostname:** `claude-dev` (or whatever you prefer)
3. Click "Create Droplet"
4. Note the IP address when it's ready

## Step 5: Run Setup Script

SSH into your new droplet as root:

```bash
ssh root@YOUR_DROPLET_IP
```

Then run the setup script:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USER/claude-code-everywhere/main/scripts/setup.sh -o setup.sh
bash setup.sh "YOUR_SSH_PUBLIC_KEY"
```

Replace `YOUR_SSH_PUBLIC_KEY` with the full contents of your `~/.ssh/id_ed25519.pub`.

## Step 6: Test Connection

Disconnect from root and connect as the dev user:

```bash
ssh dev@YOUR_DROPLET_IP
```

You should be automatically dropped into a tmux session.

## Step 7: Authenticate Claude Code

Inside the tmux session (Window 1: code):

```bash
claude
```

Follow the browser-based authentication prompt. You'll need to open the auth URL on a device with a browser (your phone works).

## Optional: Enable Backups

DigitalOcean backups cost 20% of droplet price ($3.60/mo for $18 droplet).
Still covered by your student credits.

1. Go to Droplets → your droplet → Backups
2. Enable weekly backups

## Recommended: Cloud Firewall (Defense-in-Depth)

DigitalOcean has its own cloud firewall in addition to UFW on the server. This protects even if UFW is misconfigured.

1. Go to Networking → Firewalls → Create Firewall
2. Inbound rules:
   - TCP 22 (SSH) from All IPv4, All IPv6
   - UDP 60000-61000 (mosh) from All IPv4, All IPv6
3. Outbound: Allow all (default)
4. Apply to your droplet
```

**Step 2: Commit**

```bash
git add docs/DIGITALOCEAN-SETUP.md
git commit -m "docs: add DigitalOcean droplet setup guide"
```

---

### Task 8: Write Termius iPhone setup guide

**Files:**
- Create: `docs/TERMIUS-SETUP.md`

**Step 1: Write the guide**

Write `docs/TERMIUS-SETUP.md`:

```markdown
# Termius iPhone Setup Guide

## Step 1: Install Termius

1. Open App Store on your iPhone
2. Search for "Termius"
3. Install **Termius - Modern SSH Client** (free)

## Step 2: Import Your SSH Key

Option A — Generate in Termius:
1. Open Termius → Keychain → "+" → Generate Key
2. Type: Ed25519
3. Copy the public key and add it to your droplet's `~/.ssh/authorized_keys`

Option B — Import existing key:
1. Open Termius → Keychain → "+" → Import Key
2. Paste your private key (from `~/.ssh/id_ed25519` on your computer)
3. Optionally set a passphrase

## Step 3: Create Host Entry

1. Open Termius → Hosts → "+"
2. Configure:
   - **Label:** Claude Dev
   - **Hostname:** YOUR_DROPLET_IP
   - **Port:** 22
   - **Username:** dev
   - **Key:** Select the SSH key from Step 2
3. Save

## Step 4: Enable Mosh

1. Tap the host entry you just created → Edit
2. Scroll down to **Use Mosh** → Enable it
3. Mosh ports: 60000-61000 (default, matches our UFW config)
4. Save

## Step 5: Connect

1. Tap "Claude Dev" to connect
2. First connection: accept the server fingerprint
3. You'll be automatically dropped into your tmux Claude Code session

## Keyboard Tips for tmux on iPhone

tmux prefix is `Ctrl-b`. In Termius:

| Action | Keys |
|--------|------|
| Switch to window 1 (claude) | `Ctrl-b` then `1` |
| Switch to window 2 (shell) | `Ctrl-b` then `2` |
| Create new window | `Ctrl-b` then `c` |
| Scroll up (copy mode) | `Ctrl-b` then `[` then swipe/arrow up |
| Exit scroll mode | `q` |
| Detach (keep session running) | `Ctrl-b` then `d` |

Termius has a special keyboard toolbar at the top with Ctrl, Alt, and arrow keys — use it for tmux shortcuts.

## Tips for Comfortable Mobile Coding

- **Use a Bluetooth keyboard** for longer sessions — massive improvement
- **Landscape mode** gives you more terminal columns
- **Customize Termius font size** in Settings → Appearance if text is too small
- **mosh handles network switches** — don't worry about losing your session when moving between WiFi and cellular
- **Just close the app** when done — tmux keeps Claude Code running on the server. When you reopen Termius, you'll pick up exactly where you left off.

## Troubleshooting

**"Connection refused"**
- Check that your droplet IP is correct
- Verify UFW allows port 22: `sudo ufw status`

**"Permission denied"**
- Make sure you're using username `dev` (not `root`)
- Verify your SSH key matches what's in `~/.ssh/authorized_keys` on the server

**Mosh not connecting**
- Check UFW allows UDP 60000-61000: `sudo ufw status`
- Try disabling mosh in Termius and use plain SSH to diagnose

**tmux session not auto-attaching**
- SSH in and run `start-claude.sh` manually
- Check `~/.bashrc` has the auto-attach block

## Alternative: Moshi (AI-Focused Terminal)

[Moshi](https://getmoshi.app) is a newer iOS terminal app built specifically for AI coding agents:
- Native mosh support
- **Built-in push notifications** for agent events (could replace ntfy)
- Voice input for commands
- Mobile-optimized keyboard
- Currently in free beta

Termius is recommended as the primary client (proven, stable). Try Moshi as a secondary option if its built-in notifications appeal to you.
```

**Step 2: Commit**

```bash
git add docs/TERMIUS-SETUP.md
git commit -m "docs: add Termius iPhone setup guide"
```

---

### Task 9: Create ntfy notification hook

**Files:**
- Create: `config/claude-settings.json`
- Create: `scripts/setup-notifications.sh`

**Step 1: Write the Claude Code settings with ntfy hook**

Write `config/claude-settings.json`. This gets deployed to `~/.claude/settings.json` on the droplet.

Note: In user settings.json, hook event names are top-level keys — no `"hooks"` wrapper.

```json
{
  "Stop": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "curl -s -d \"Claude Code finished a task\" ${NTFY_TOPIC:-ntfy.sh/claude-dev-notify}"
        }
      ]
    }
  ]
}
```

**Step 2: Write the notification setup helper script**

Write `scripts/setup-notifications.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Setup ntfy notifications for Claude Code
# Usage: bash setup-notifications.sh <your-ntfy-topic>
# Example: bash setup-notifications.sh claude-dafan

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
```

**Step 3: Make executable and commit**

```bash
chmod +x scripts/setup-notifications.sh
git add config/claude-settings.json scripts/setup-notifications.sh
git commit -m "feat: add ntfy push notification hook for Claude Code"
```

---

### Task 10: Create Linear MCP configuration

**Files:**
- Create: `config/mcp.json`
- Create: `docs/LINEAR-SETUP.md`

**Step 1: Write MCP config for Linear**

Write `config/mcp.json`. This gets deployed to `~/.claude/.mcp.json` or project-level `.mcp.json`:

```json
{
  "mcpServers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.linear.app/sse"]
    }
  }
}
```

**Step 2: Write Linear setup guide**

Write `docs/LINEAR-SETUP.md`:

```markdown
# Linear Integration Setup

Connect Claude Code to your Linear workspace so it can read tickets, implement them, and update status.

## Step 1: Configure MCP

On your droplet, add the Linear MCP server to Claude Code:

```bash
# Option A: Use the Claude Code command
claude
# Then type: /mcp
# Add server → name: linear → command: npx -y mcp-remote https://mcp.linear.app/sse

# Option B: Copy the config file
cp config/mcp.json ~/.claude/.mcp.json
```

## Step 2: Authenticate

First time you use a Linear tool in Claude Code, it will prompt you to authenticate:

1. Claude Code shows an auth URL
2. Open it on your phone browser
3. Authorize Claude Code to access your Linear workspace
4. Done — one-time setup

## Step 3: Usage

Once connected, you can tell Claude Code:

- "Show me my assigned Linear issues"
- "Pick up LIN-42 and implement it"
- "Create a new issue for the auth bug I just found"
- "Update LIN-42 status to In Review and add a comment with the PR link"
- "What are the highest priority tickets in the current sprint?"

## Autonomous Workflow

Combine Linear + autonomous mode for the full "climbing gym" experience:

```bash
claude -p "Check my Linear issues, pick the highest priority one, implement it with tests, commit, push to a feature branch, create a PR, and update the Linear issue status to In Review with the PR link" --yes
```

Then go climb. ntfy will notify you when it's done.
```

**Step 3: Commit**

```bash
git add config/mcp.json docs/LINEAR-SETUP.md
git commit -m "feat: add Linear MCP integration config and setup guide"
```

---

### Task 11: Create GitLab setup guide

**Files:**
- Create: `docs/GITLAB-SETUP.md`

**Step 1: Write the GitLab setup guide**

Write `docs/GITLAB-SETUP.md`:

```markdown
# GitLab Setup Guide (for SE Project / Commercial Work)

This guide sets up GitLab access on your droplet for the your-project project with your company partner.

## Prerequisites

- GitLab account (your college email registered by the team lead)
- Access to the project repository on GitLab

## Step 1: Add SSH Key to GitLab

Your droplet already has an SSH key (generated by setup.sh). Add it to GitLab:

```bash
cat ~/.ssh/id_ed25519.pub
```

1. Copy the output
2. Go to GitLab → Preferences → SSH Keys (or your company GitLab instance)
3. Paste the key, title it "Claude Dev Droplet"
4. Save

Test it:
```bash
ssh -T git@gitlab.com
# or for company GitLab:
ssh -T git@gitlab.your-company.example.com
```

## Step 2: Authenticate glab CLI

```bash
glab auth login
```

Choose:
- GitLab instance (gitlab.com or self-hosted URL)
- Authenticate via browser or personal access token
- For tokens: create one at GitLab → Preferences → Access Tokens
  - Scopes needed: api, read_repository, write_repository

## Step 3: Clone the Project

```bash
cd ~
git clone git@gitlab.com:YOUR_GROUP/your-project.git
# or company GitLab:
git clone git@gitlab.your-company.example.com:YOUR_GROUP/your-project.git
cd your-project
```

## Step 4: Set Up GitLab MCP (optional)

Connect Claude Code to GitLab directly:

```bash
claude mcp add --transport http GitLab https://gitlab.com/api/v4/mcp
# or for company GitLab:
claude mcp add --transport http GitLab https://gitlab.your-company.example.com/api/v4/mcp
```

This lets Claude Code read issues, create MRs, and check pipelines natively.

## Step 5: Configure Git Identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your-college-email@example.com"
```

Use the same email registered with GitLab.

## Workflow: Working on the SE Project from Phone

```bash
# Start Claude Code in the project directory
cd ~/your-project
claude

# Tell Claude what to do:
# "Pick up PROJ-42, implement the risk scoring endpoint following
#  the patterns in apps/api/CLAUDE.md, write integration tests,
#  create a feature branch your-name/feat/PROJ-42-risk-scoring,
#  commit, push, and create a merge request"
```

## Creating Merge Requests

```bash
# Via glab CLI
glab mr create \
  --title "PROJ-42 feat(api): add risk scoring endpoint" \
  --description "Implements ML-based risk scoring pipeline" \
  --source-branch your-name/feat/PROJ-42-risk-scoring

# Or let Claude Code do it:
# "Create a merge request for this branch with a proper description"
```

## Project-Specific Notes

- Branch naming: `<name>/<type>/<PROJ-XX>-<short-description>`
- MR title format: `<PROJ-XX> <type>(scope): description`
- Always run `make lint` and `make test` before pushing
- The project CLAUDE.md at repo root has all conventions
```

**Step 2: Commit**

```bash
git add docs/GITLAB-SETUP.md
git commit -m "docs: add GitLab setup guide for commercial SE project"
```

---

### Task 12: Update DigitalOcean guide with GitHub/GitLab sync and submission steps

**Files:**
- Modify: `docs/DIGITALOCEAN-SETUP.md`

**Step 1: Add post-setup GitHub section to the guide**

Append to `docs/DIGITALOCEAN-SETUP.md` after the "Authenticate Claude Code" step:

```markdown
## Step 8: Set Up GitHub Access (for pushing code and creating PRs)

The setup script generated an SSH key for your droplet. You need to add it to GitHub so the server can push code and create PRs.

1. SSH into your server and copy the public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. Go to [github.com/settings/keys](https://github.com/settings/keys)
3. Click "New SSH key"
4. Title: "Claude Dev Droplet"
5. Paste the key and save

Test it works:
```bash
ssh -T git@github.com
```
Expected: "Hi YOUR_USERNAME! You've successfully authenticated..."

## Step 9: Authenticate GitHub CLI

This lets you (and Claude Code) create PRs, manage issues, and more directly from the server.

```bash
gh auth login
```

Choose:
- GitHub.com
- SSH
- Your existing SSH key
- Login with a web browser (open the URL on your phone)

Test it works:
```bash
gh auth status
```

## Workflow: Submitting Work from the Droplet

Once GitHub access is set up, your droplet can submit work independently:

```bash
# Push commits
git push origin main

# Create a pull request
gh pr create --title "Add feature X" --body "Description"

# Merge a PR
gh pr merge 123

# Clone a new repo to work on
git clone git@github.com:YOUR_USER/your-repo.git
```

Claude Code can do all of this for you — just ask it to "push this" or "create a PR".

## Syncing Back to Your Mac

When you're at your desk and want the latest code:

```bash
git pull origin main
```

All work done on the droplet is on GitHub. Your Mac just pulls it down.
```

**Step 2: Commit**

```bash
git add docs/DIGITALOCEAN-SETUP.md
git commit -m "docs: add GitHub sync and submission workflow to DO guide"
```

---

### Task 13: Add .gitignore, LICENSE, and .env.example

**Files:**
- Create: `.gitignore`
- Create: `LICENSE`
- Create: `.env.example`

**Step 1: Write .gitignore**

Write `.gitignore`:

```
# Private config (never commit)
.env.local
.local/
*.pem
*.key

# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/
*.swp
*.swo
```

**Step 2: Write LICENSE (MIT)**

Write `LICENSE`:

```
MIT License

Copyright (c) 2026 Claude Code Everywhere Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Step 3: Write .env.example**

Write `.env.example`:

```bash
# Claude Code Everywhere — Configuration
# Copy to .env.local and fill in your values:
#   cp .env.example .env.local

# Server username (default: dev)
USERNAME=dev

# ntfy push notification topic (pick a unique name)
# Install ntfy app on phone → subscribe to this topic
NTFY_TOPIC=ntfy.sh/claude-YOUR_USERNAME

# GitLab instance URL (leave blank for gitlab.com)
# For self-hosted: https://gitlab.your-company.com
GITLAB_URL=

# GitLab MCP endpoint (auto-derived from GITLAB_URL)
# GITLAB_MCP_URL=${GITLAB_URL}/api/v4/mcp
```

**Step 4: Commit**

```bash
git add .gitignore LICENSE .env.example
git commit -m "chore: add gitignore, MIT license, and env example"
```

---

### Task 14: Sanitize docs — remove personal/commercial info

**Files:**
- Modify: `docs/plans/2026-03-02-claude-code-mobile-design.md`
- Modify: `docs/GITLAB-SETUP.md`
- Modify: `CLAUDE.md`

**Step 1: In all docs, replace personal/commercial references with generic placeholders**

Replace company domains, project names, team names, and course references with generic equivalents like `your-company.example.com`, `your-project`, `PROJ`, etc.

**Step 2: In CLAUDE.md, generalize the target user context**

Replace the specific project details with generic placeholders. Keep the structure but remove company/project names.

**Step 3: In GITLAB-SETUP.md, generalize**

Replace specific company GitLab URLs with `gitlab.your-company.example.com` placeholders.

**Step 4: Commit**

```bash
git add -A
git commit -m "docs: sanitize personal/commercial info for public repo"
```

---

### Task 15: Create Makefile

**Files:**
- Create: `Makefile`

**Step 1: Write Makefile**

Write `Makefile`:

```makefile
.PHONY: setup notifications health backup restore help

# Load .env.local if it exists
-include .env.local
export

SSH_KEY ?= $(shell cat ~/.ssh/id_ed25519.pub 2>/dev/null)
USERNAME ?= dev
NTFY_TOPIC ?= ntfy.sh/claude-dev-notify

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Run full server setup (run as root on droplet)
	@if [ -z "$(SSH_KEY)" ]; then echo "Error: SSH_KEY required. Usage: make setup SSH_KEY=\"ssh-ed25519 ...\""; exit 1; fi
	sudo bash scripts/setup.sh "$(SSH_KEY)"

notifications: ## Configure ntfy push notifications
	bash scripts/setup-notifications.sh "$(NTFY_TOPIC)"

health: ## Check server health
	bash scripts/health-check.sh

backup: ## Backup server config to ~/backups/
	bash scripts/backup.sh

restore: ## Restore server config from backup
	bash scripts/restore.sh

test-docker: ## Test setup.sh in Docker (local validation)
	docker run --rm -it -v "$$(pwd)/scripts:/scripts" ubuntu:24.04 bash -c \
		'apt-get update -qq && apt-get install -y -qq sudo curl && bash /scripts/setup.sh "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest123 test@test"'
```

**Step 2: Commit**

```bash
git add Makefile
git commit -m "feat: add Makefile for common operations"
```

---

### Task 16: Create health check script

**Files:**
- Create: `scripts/health-check.sh`

**Step 1: Write health-check.sh**

Write `scripts/health-check.sh`:

```bash
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
```

**Step 2: Make executable and commit**

```bash
chmod +x scripts/health-check.sh
git add scripts/health-check.sh
git commit -m "feat: add health check script"
```

---

### Task 17: Create backup/restore scripts

**Files:**
- Create: `scripts/backup.sh`
- Create: `scripts/restore.sh`

**Step 1: Write backup.sh**

Write `scripts/backup.sh`:

```bash
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
```

**Step 2: Write restore.sh**

Write `scripts/restore.sh`:

```bash
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
```

**Step 3: Make executable and commit**

```bash
chmod +x scripts/backup.sh scripts/restore.sh
git add scripts/backup.sh scripts/restore.sh
git commit -m "feat: add backup and restore scripts"
```

---

### Task 18: Update README for public release

**Files:**
- Modify: `README.md`

**Step 1: Rewrite README.md**

Rewrite `README.md` with the full feature set, generic (no personal info), and professional:

```markdown
# Claude Code Everywhere

Run Claude Code CLI from your phone. Ship code from anywhere.

A fully automated setup for running Claude Code on a cloud server (DigitalOcean), accessible from your iPhone via [Termius](https://termius.com/) + mosh + tmux. Includes push notifications, Linear/GitLab integration, and autonomous "fire-and-forget" workflows.

## What This Does

- **Full dev environment** on a cloud server (Node.js, Python, Docker, and more)
- **SSH from your phone** via Termius with mosh (survives network switches)
- **Persistent sessions** via tmux (disconnect and reconnect without losing state)
- **Push notifications** via ntfy when Claude Code finishes a task
- **Linear integration** — Claude reads tickets, implements, pushes, updates status
- **GitHub + GitLab** support — push code, create PRs/MRs from the server
- **Autonomous mode** — kick off a task from your phone, go do something else, get notified when done

## Quick Start

### Prerequisites

- [DigitalOcean account](https://www.digitalocean.com/) ($200 free with [GitHub Student Pack](https://education.github.com/pack))
- [Claude Pro/Max subscription](https://claude.ai/)
- iPhone with [Termius](https://termius.com/) (free tier)
- SSH key pair

### Setup

1. Create a DigitalOcean droplet — see [docs/DIGITALOCEAN-SETUP.md](docs/DIGITALOCEAN-SETUP.md)

2. SSH in as root and run setup:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/YOUR_USER/claude-code-everywhere/main/scripts/setup.sh -o setup.sh
   bash setup.sh "$(cat ~/.ssh/id_ed25519.pub)"
   ```

3. Configure Termius on your iPhone — see [docs/TERMIUS-SETUP.md](docs/TERMIUS-SETUP.md)

4. Connect and authenticate Claude Code:
   ```bash
   claude
   ```

5. (Optional) Set up push notifications — see `make notifications`

6. (Optional) Connect Linear/GitLab — see [docs/LINEAR-SETUP.md](docs/LINEAR-SETUP.md) and [docs/GITLAB-SETUP.md](docs/GITLAB-SETUP.md)

## Usage

### Interactive (from phone)
```bash
# Open Termius → tap your server → you're in tmux with Claude Code
claude
> Fix the authentication bug in login.ts and write tests
```

### Autonomous (fire-and-forget)
```bash
# Kick off a task, close Termius, go do something else
claude -p "Implement the API endpoint from ticket LIN-42, write tests, commit and push, create a PR" --yes
# You'll get a push notification when it's done
```

## Commands

```bash
make help           # Show all commands
make setup          # Run full server setup
make notifications  # Configure ntfy push notifications
make health         # Check server health
make backup         # Backup server config
make restore        # Restore from backup
make test-docker    # Test setup.sh in Docker locally
```

## Configuration

Copy `.env.example` to `.env.local` and customize:

```bash
cp .env.example .env.local
```

See `.env.example` for all configurable values (username, ntfy topic, GitLab URL).

## Architecture

```
Phone (Termius) → mosh → DigitalOcean Droplet (tmux → Claude Code CLI)
                                ↓
                         GitHub / GitLab (push, PRs, MRs)
                                ↓
                         ntfy.sh → Phone notification
```

## Guides

- [DigitalOcean Setup](docs/DIGITALOCEAN-SETUP.md) — Create droplet with student credits
- [Termius Setup](docs/TERMIUS-SETUP.md) — iPhone SSH client configuration
- [Linear Integration](docs/LINEAR-SETUP.md) — Connect Claude Code to Linear
- [GitLab Integration](docs/GITLAB-SETUP.md) — For commercial/team projects

## What's Installed

| Category | Tools |
|----------|-------|
| AI | Claude Code CLI (native, auto-updates) |
| Languages | Node.js 22 LTS, Python 3 + pip |
| Data Science | pandas, numpy, scikit-learn, matplotlib, seaborn, jupyter |
| Containers | Docker, docker-compose |
| VCS | git, gh (GitHub CLI), glab (GitLab CLI) |
| Terminal | mosh, tmux |
| Security | UFW, fail2ban, SSH key-only auth, auto security updates |
| Notifications | ntfy.sh hooks |
| Project Mgmt | Linear MCP, GitLab MCP |

## Cost

| Item | Cost |
|------|------|
| Server | $0 with GitHub Student Pack ($200 credit) |
| Claude Pro | $20/mo (existing subscription) |
| Termius | Free |
| ntfy | Free |
| Linear | Free (personal) |

## License

MIT
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README for public release"
```

---

### Task 19: Test setup.sh in a local Docker container

**Files:** None (validation task)

**Step 1: Create a quick test with Docker**

Test the script doesn't error out on a clean Ubuntu 24.04 image:

```bash
cd ~/Documents/Personal/claude-code-everywhere
docker run --rm -it -v "$(pwd)/scripts:/scripts" ubuntu:24.04 bash -c '
  apt-get update -qq && apt-get install -y -qq sudo curl &&
  bash /scripts/setup.sh "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest123 test@test"
'
```

Expected: Script runs through all 8 steps without errors. Some services (systemctl) may warn in Docker — that's OK, they work on a real droplet.

**Step 2: Verify key files were created**

```bash
docker run --rm -it -v "$(pwd)/scripts:/scripts" ubuntu:24.04 bash -c '
  apt-get update -qq && apt-get install -y -qq sudo curl &&
  bash /scripts/setup.sh "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest123 test@test" &&
  echo "--- Checking files ---" &&
  ls -la /home/dev/.tmux.conf &&
  ls -la /home/dev/bin/start-claude.sh &&
  ls -la /home/dev/bin/update.sh &&
  cat /etc/ssh/sshd_config.d/99-hardened.conf &&
  cat /etc/fail2ban/jail.local
'
```

Expected: All files exist with correct permissions.

**Step 3: Fix any issues and commit**

```bash
git add -A
git commit -m "fix: address issues found during Docker validation"
```

---

### Task 20: Final commit and summary

**Step 1: Verify all files are committed**

```bash
git status
git log --oneline
```

Expected: Clean working tree, ~7-8 commits.

**Step 2: Tag the release**

```bash
git tag v1.0.0
```

**Step 3: Output final summary**

The project is ready. User should:
1. Push to GitHub
2. Follow `docs/DIGITALOCEAN-SETUP.md` to create droplet
3. Run `setup.sh` on the droplet
4. Follow `docs/TERMIUS-SETUP.md` to configure iPhone
5. Connect and authenticate Claude Code
