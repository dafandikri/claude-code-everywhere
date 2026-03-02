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
