# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Project Purpose

**Claude Code Everywhere** is an infrastructure project that sets up a cloud-based development environment for running Claude Code CLI from a mobile phone (iPhone via Termius). It enables autonomous, commercial-grade software development from anywhere.

## What This Repo Contains

- `scripts/` — Server setup automation (setup.sh, convenience scripts, notification setup)
- `config/` — Configuration files deployed to the server (tmux, SSH, fail2ban, Claude Code hooks, MCP)
- `docs/` — Setup guides (DigitalOcean, Termius, Linear, GitLab) and design plans

This is NOT an application — it's infrastructure/DevOps tooling. There are no tests to run, no build steps. The "product" is the setup script and configuration files.

## Key Design Decisions

- **DigitalOcean droplet** over laptop hosting — reliability for commercial work (99.99% SLA)
- **mosh over SSH** — survives network switches on mobile
- **tmux** — persistent sessions that outlive connections
- **ntfy.sh** — push notifications when Claude Code finishes tasks
- **Both GitHub and GitLab** supported — GitHub for personal, GitLab for commercial SE projects

## Working With This Repo

### File Conventions

- Shell scripts: `bash`, `set -euo pipefail`, shellcheck-clean
- Config files: commented with purpose and where they deploy to
- Docs: Markdown, step-by-step with exact commands

### When Editing setup.sh

- Keep step numbering consistent (e.g., `[1/10]`, `[2/10]`)
- Every package install must be in the apt-get block or have a comment explaining why it's separate
- Test changes with Docker before deploying: `docker run --rm -it -v "$(pwd)/scripts:/scripts" ubuntu:24.04 bash`

### Git Operations

- **NEVER auto-commit or auto-push** — wait for explicit user instruction
- Branch naming: `feat/description`, `fix/description`, `docs/description`
- Commit style: `feat: add ntfy notification hook`, `docs: update GitLab setup guide`

## Target User Context

The primary user is a college student doing:
- **Commercial SE project** — Smart Invoice Reminder AI (PPL-SIRA) with Nashta Group
  - Uses GitLab (company-provided), Linear for PM, domain: nashtagroup.co.id
  - Must ship commercial-grade code
- **Data mining** coursework — Python, pandas, scikit-learn, Jupyter
- **Research methods** — academic writing, data analysis
- Wants to work from iPhone while away from desk (gym, transit, class)

## Server Environment (What setup.sh Creates)

The droplet runs Ubuntu 24.04 with:
- Claude Code CLI (native installer, auto-updates)
- Node.js 22 LTS (via nvm), Python 3 + pip + data science stack
- Docker + docker-compose
- git, gh (GitHub CLI), glab (GitLab CLI)
- mosh, tmux, fail2ban, UFW
- ntfy hooks for push notifications
- Linear MCP + GitLab MCP for project management integration
