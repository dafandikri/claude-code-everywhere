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
