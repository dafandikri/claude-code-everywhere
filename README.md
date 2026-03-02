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
