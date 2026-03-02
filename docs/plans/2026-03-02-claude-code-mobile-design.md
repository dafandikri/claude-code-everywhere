# Claude Code Mobile: System Design

**Date:** 2026-03-02
**Status:** Approved

## Problem

Use Claude Code CLI from an iPhone with full development capabilities. The web/desktop Claude Code is limited compared to CLI. Need a persistent, reliable remote environment accessible from mobile.

## Solution

DigitalOcean droplet + Termius (iOS SSH app) + mosh + tmux.

## Architecture

```
iPhone (Termius) --mosh (UDP)--> DigitalOcean Droplet (Ubuntu 24.04)
                                   |
                                   +-- tmux session
                                   |    +-- Window 0: Claude Code CLI
                                   |    +-- Window 1: Shell (git, dev servers)
                                   |    +-- Window 2: Logs (optional)
                                   |
                                   +-- mosh-server
                                   +-- Node.js 22 LTS
                                   +-- Git + GitHub SSH keys
                                   +-- UFW firewall
                                   +-- fail2ban
```

## Connection Flow

**Interactive mode (working from phone):**
1. Open Termius on iPhone
2. Tap saved "Dev Server" mosh connection
3. Auto-attaches to existing tmux session
4. Claude Code is running, exactly where you left off

**Autonomous "climbing gym" mode:**
1. Open Termius, kick off a task:
   ```bash
   claude -p "Pick up LIN-123 from Linear, implement it, write tests, commit and push, update Linear status" --yes
   ```
2. Close Termius. Go climb.
3. Get a push notification on iPhone (via ntfy) when Claude finishes.
4. Review the PR from the GitHub app on your phone — approve or request changes.

## Why mosh over plain SSH

- Survives WiFi/cellular switches seamlessly
- Resumes instantly after phone sleep/wake
- Local echo for responsive typing on high-latency cellular
- Buffers locally during signal drops, catches up automatically

## Server Specification

- **Provider:** DigitalOcean
- **Region:** Closest to user (e.g., sgp1)
- **OS:** Ubuntu 24.04 LTS
- **Size:** $18/month - 2GB RAM / 2 vCPUs / 60GB SSD (can resize to 4GB/$24 if needed)
- **Auth:** SSH key only

**Why 2 vCPUs:** Autonomous Claude Code tasks benefit from the extra core — one for Claude, one for build/test processes. The $18/mo plan is the sweet spot for your workload. $200 credit covers ~11 months.

**Resize if needed:** DigitalOcean lets you resize in minutes (no data loss). Go to 4GB/$24 only if you're running Jupyter + Docker + Claude all at once.

## Budget

**Recommended: $18/mo droplet (2GB RAM / 2 vCPUs / 60GB SSD)** — enough for Claude Code + Docker + Python data science. Upgrade to $24/mo (4GB) only if running Jupyter + Docker containers + Claude simultaneously.

| Item | Monthly | 12-Month Total | Source |
|------|---------|----------------|--------|
| DigitalOcean Droplet ($18/mo) | $18 | $216 | GitHub Student Pack ($200 credit covers ~11 months) |
| Claude Pro | $20 | $240 | Existing subscription |
| Termius (free tier) | $0 | $0 | Free |
| ntfy (free tier) | $0 | $0 | Free |
| Linear (free tier) | $0 | $0 | Free for personal use |
| **Server out-of-pocket** | **$0** | **~$16 total** | $200 credit covers 11 months, last month ~$16-18 |

After 12 months: re-qualify for student benefits, pay $18/mo, or migrate to Oracle Cloud Free Tier.

## Security

1. SSH key-only authentication (password login disabled)
2. UFW firewall: allow ports 22 (SSH) + 60000-61000 (mosh UDP) only
3. DigitalOcean Cloud Firewall (additional layer — same rules as UFW, defense-in-depth)
4. Non-root user for daily use, root SSH disabled
5. fail2ban for brute-force protection
6. Automatic security updates via unattended-upgrades

## Server Tuning

**Swap space (essential for 2GB RAM):**
- 2GB swap file prevents OOM kills when running Docker + Claude Code + Node.js simultaneously
- Costs nothing, just uses disk space

**Timezone:**
- Set to `Asia/Jakarta` for Indonesian-local timestamps in logs and git commits

**Git identity:**
- `git config --global` set during setup for correct commit authorship from the droplet

## Software Stack

**Infrastructure:**
- mosh (mobile shell server)
- tmux (session persistence)
- Claude Code CLI (native installer)
- git + SSH keys for GitHub
- gh (GitHub CLI — for PRs, issues, repo management)

**Dev Environment (match Mac capabilities):**
- nvm + Node.js 22 LTS + npm (full-stack JS/TS)
- Python 3 + pip + venv (data mining, research, general)
- Docker + docker-compose (run databases, services, containers)
- build-essential + gcc + make (compile native modules)
- PostgreSQL client (connect to databases)
- CLI tools: jq, ripgrep, htop, wget, zip, unzip

**Data Mining / Academic:**
- Python packages: pandas, numpy, scikit-learn, matplotlib, seaborn, jupyter
- Jupyter notebook accessible via SSH tunnel from phone/Mac

**Integrations:**
- Linear MCP server — Claude Code reads/creates/updates Linear issues natively
- ntfy.sh — push notifications to iPhone when Claude finishes tasks
- Claude Code hooks — auto-notify on Stop events, validate work before completing

**How Jupyter works on the droplet:**
Start Jupyter on the server, tunnel it to your device:
```bash
# On the droplet (inside tmux)
jupyter notebook --no-browser --port=8888

# On your Mac (SSH tunnel)
ssh -L 8888:localhost:8888 dev@YOUR_IP
# Then open http://localhost:8888 in your browser

# On iPhone: use Termius port forwarding
# Forward local 8888 → remote 8888, open Safari to localhost:8888
```

## Notification System (ntfy)

ntfy.sh sends push notifications to your iPhone when Claude Code finishes a task, encounters an error, or needs your input. This is what lets you leave the desk and go climbing.

**How it works:**
```
Claude Code (on droplet)
    → finishes task / hits error
    → triggers "Stop" hook
    → hook sends HTTP POST to ntfy.sh
    → ntfy.sh pushes to iPhone notification
    → you see it at the gym
```

**Setup:**
1. Install ntfy app on iPhone (free, App Store)
2. Subscribe to your private topic (e.g., `claude-YOUR_USERNAME`)
3. Claude Code hook sends to that topic on Stop events

**Hook config** (`~/.claude/settings.json` on droplet):

Note: In user settings.json, hook event names are top-level keys (no `"hooks"` wrapper).

```json
{
  "Stop": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "curl -s -d \"Claude Code finished: $(cat /tmp/claude-last-task 2>/dev/null || echo 'task complete')\" ntfy.sh/claude-YOUR_USERNAME"
        }
      ]
    }
  ]
}
```

## Linear Integration (MCP)

Claude Code connects to Linear via its official MCP server. This means Claude can:

- Read your Linear tickets and understand requirements
- Create issues, update status, add comments
- Pick up a ticket, implement it, push code, and mark it done — autonomously

**Setup:** Run `/mcp` in Claude Code and add the Linear server, or configure `.mcp.json`:
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

Authenticate once via browser. After that, Claude Code can interact with your Linear workspace.

## GitLab Integration (for SE Project / Commercial Work)

The SE project (your-project / your SE project) uses GitLab provided by your company partner. The droplet supports both GitHub (personal projects) and GitLab (commercial projects).

**Tools installed:**
- `glab` — GitLab CLI (create MRs, manage issues, pipelines)
- GitLab MCP server — Claude Code can interact with GitLab natively

**GitLab MCP setup:**
```bash
# Add GitLab MCP server to Claude Code
claude mcp add --transport http GitLab https://gitlab.com/api/v4/mcp
```

Or if using a self-hosted GitLab (e.g., your company partner's instance):
```bash
claude mcp add --transport http GitLab https://gitlab.your-company.example.com/api/v4/mcp
```

**What Claude Code can do via GitLab MCP:**
- Read issues and merge request details
- Create merge requests
- Review and implement changes from MR feedback
- Interact with GitLab pipelines
- Push code to GitLab repos

**glab CLI usage (for when MCP isn't enough):**
```bash
# Authenticate
glab auth login

# Create a merge request
glab mr create --title "PROJ-42 feat(api): add new endpoint" --description "..."

# View pipeline status
glab ci status

# List assigned issues
glab issue list --assignee=@me
```

**SSH key for GitLab:** Same SSH key generated by setup.sh works for both GitHub and GitLab. Add the droplet's public key to your GitLab account:
```bash
cat ~/.ssh/id_ed25519.pub
# → Add to gitlab.com (or company GitLab) → Preferences → SSH Keys
```

## Commercial Project Context

The SE project involves a real company (your company partner):
- **Domains:** `app.your-company.example.com` (frontend), `api.your-company.example.com` (backend)
- **GitLab:** Company-provided, shared with team
- **Linear workspace:** `your-project`, team `your-project` (key: `PROJ`)
- **Stack:** React + Vite (frontend), FastAPI + Celery (backend), Supabase, Docker
- **Quality bar:** Commercial-grade — typed code, tested, linted, reviewed

The droplet's dev environment matches this stack: Node.js, Python, Docker, and all required tooling are pre-installed by setup.sh.

## Devin Comparison

This setup is essentially a DIY Devin at a fraction of the cost:

| | Devin | This Setup |
|---|-------|------------|
| Price | $20/mo + $2.25 per ~15min of agent work | $20/mo Claude Pro flat (server $0 with student credits) |
| Autonomy | Fully autonomous (assign via Slack) | Autonomous via `claude -p "task" --yes` |
| Environment | Cloud sandbox | Full Linux server (more control, any tools) |
| From phone | Slack | Termius SSH + ntfy notifications |
| Fire-and-forget | Yes | Yes — tmux + ntfy notifies you when done |
| Create PRs | Yes | Yes — `gh pr create` |
| Project management | Jira/Linear (read-only) | Linear MCP (full read/write) |
| Notifications | Slack | ntfy push notifications to iPhone |
| Dev tools | Limited sandbox | Docker, Python, Node, Jupyter, anything |
| Data science | No | Pandas, scikit-learn, Jupyter, matplotlib |
| Cost for 40hrs/mo | ~$360+ ($2.25/ACU) | $20 flat |

## What You Can Do From Your Phone (Same as Mac)

Everything your Mac can do with Claude Code, the droplet can do too:

| Task | How |
|------|-----|
| Build a full-stack web app | Node.js + Python + Docker all installed |
| Data mining assignments | Python + pandas + scikit-learn + Jupyter |
| Software engineering project | Git + GitHub + PRs + Docker + any framework |
| Research & analysis | Python + matplotlib/seaborn for charts, Jupyter for notebooks |
| Run databases | Docker (PostgreSQL, MongoDB, Redis, etc.) |
| Submit homework (push to GitHub) | `git push` or `gh pr create` — Claude Code does it for you |
| Run tests | Any test framework, Claude Code runs them automatically |
| Deploy apps | Docker, or push to Vercel/Netlify/Railway from server |
| Pick up Linear tickets | Linear MCP — Claude reads ticket, implements, pushes, updates status |
| Get notified when done | ntfy.sh push notification to your iPhone |

## The Climbing Gym Workflow

This is the core use case — kick off work, go live your life, get notified when it's done.

```
1. At home/cafe: Open Termius on iPhone
2. Tell Claude what to do:
   claude -p "Pick up LIN-42, implement the data preprocessing
   pipeline from the spec, write tests, commit and push to
   feature branch, create PR, update Linear" --yes
3. Close Termius. Go to climbing gym.
4. 📱 ntfy notification: "Claude Code finished: LIN-42 implemented, PR #7 created"
5. Open GitHub app on phone → review the PR
6. Approve + merge from your phone, or leave notes for next session
```

**What if Claude hits a problem?**
- ntfy notifies you: "Claude Code stopped: need clarification on database schema"
- You can open Termius at the gym, answer the question, let it continue
- Or just wait until you're back at your desk

**What if your laptop sleeps?**
- Doesn't matter. The droplet runs 24/7. Your laptop is irrelevant.
- Work continues on the server whether your laptop is open, closed, or at home.

## tmux Configuration

- Mouse support enabled (for scrolling in Termius)
- Scrollback buffer: 10,000 lines
- Status bar with session info
- Auto-start Claude Code on session create

## Setup Automation

A `setup.sh` script that automates:
1. User creation with SSH key
2. Software installation (mosh, tmux, nvm, Node.js, Claude Code)
3. Firewall configuration (UFW)
4. fail2ban setup
5. SSH hardening
6. tmux config deployment
7. Convenience scripts (start-claude.sh, update.sh)

Plus a Termius configuration guide for iPhone setup.

## Daily Workflow

**Interactive (sitting down, focused work):**
1. **Start:** Open Termius, tap connection, tmux reattaches
2. **Work:** Claude Code in window 0, shell in window 1
3. **Switch windows:** Ctrl-b + number (Termius keyboard toolbar)
4. **Disconnect:** Close app or lock phone - tmux keeps session alive
5. **Resume:** Open Termius again, back exactly where you left off

**Autonomous (on the go, at the gym, in class):**
1. Open Termius, kick off task with `claude -p "..." --yes`
2. Close Termius. Go do your thing.
3. Get ntfy push notification when done.
4. Review PR on GitHub app. Approve or leave comments.

**Linear-driven (project management):**
1. Create tickets in Linear on your phone (Linear iOS app)
2. SSH in, tell Claude: "Pick up the top priority ticket and work on it"
3. Claude reads Linear, implements, pushes, updates ticket status
4. You review when convenient

## Project Management

- Clone repos directly on the droplet (git+SSH)
- GitHub SSH keys stored on server
- Push/pull from server - phone never touches code files directly

## Sync & Submission Workflow

Git is the sync layer across all devices. The droplet can independently push code, create PRs, and submit work — no Mac or phone needed beyond the SSH session.

### Architecture

```
Your Mac ←── git pull ──→ GitHub ←── git push ──→ DO Droplet
                             ↑                       ↑
                       iPhone (browse)          Claude Code
                       GitHub app/web        (commits, pushes, PRs)
```

### Droplet can submit work independently

The droplet has its own GitHub SSH key and `gh` CLI. From a Claude Code session on your phone, the droplet can:

- `git push` — push commits to GitHub
- `gh pr create` — create pull requests
- `gh pr merge` — merge PRs
- `gh issue create` — create issues

Claude Code itself can do all of these via its built-in tools. You just tell Claude "push this" or "create a PR" and it runs the git/gh commands on the server.

### Syncing to your Mac

When you're back at your desk:

```bash
git pull origin main
```

All commits made from the droplet are on GitHub — your Mac just pulls them.

### Syncing non-Git files

| Method | Best for |
|--------|----------|
| Termius SFTP | Download individual files to iPhone (built-in, free) |
| `rsync` over SSH | Bulk sync between Mac and droplet |
| GitHub dotfiles repo | Shell configs, editor settings across machines |

### Software required on droplet

- `git` — installed by setup.sh
- `gh` (GitHub CLI) — added to setup.sh for PR creation and repo management
- SSH key for GitHub — generated during setup, user adds public key to GitHub

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Droplet downtime | DigitalOcean has 99.99% SLA; weekly backups ($2.40/mo from credits) |
| Credit expiration | Plan migration to Oracle Free Tier or budget $12/mo |
| 2GB RAM insufficient | 2GB swap file + resize droplet via DO dashboard (minutes, no data loss) |
| SSH key compromise | Use passphrase-protected keys, rotate periodically |
| OOM kills | Swap space configured by setup.sh; Docker memory limits if needed |

## Alternative: Moshi (iOS Terminal for AI Agents)

[Moshi](https://getmoshi.app) is a newer iOS terminal app built specifically for Claude Code and AI agent workflows:

- Native mosh protocol support
- **Built-in push notifications** for agent events (could replace ntfy)
- Voice input using on-device Whisper model
- Mobile-optimized keyboard with Ctrl, Esc, Tab keys
- tmux prefix shortcuts
- Currently in **free beta**

**Our recommendation:** Stick with **Termius** as the primary client — it's proven, stable, and supports mosh + SFTP on the free tier. Try Moshi as a secondary option if its built-in notifications are appealing (they could replace the ntfy setup entirely).

## DigitalOcean Cloud Firewall

In addition to UFW on the droplet, set up a DigitalOcean Cloud Firewall for defense-in-depth:
- Networking → Firewalls → Create Firewall
- Inbound: allow TCP 22 (SSH) + UDP 60000-61000 (mosh) from all sources
- Apply to your droplet
- This protects even if UFW is misconfigured or disabled
