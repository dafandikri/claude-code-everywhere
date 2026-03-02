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

# --- 8. Install Claude Code + Node.js + dev tools (as the dev user) ---
echo "[10/12] Installing Claude Code, Node.js, dev tools, and configuring tmux..."
sudo -u "$USERNAME" bash << 'USEREOF'
set -euo pipefail

# Install nvm + Node.js 22 LTS
export NVM_DIR="$HOME/.nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
# Source nvm for this session
. "$NVM_DIR/nvm.sh"
nvm install 22
nvm alias default 22

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
