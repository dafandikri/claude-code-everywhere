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
