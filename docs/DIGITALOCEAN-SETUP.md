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
   - **Size:** Regular → $18/mo (2 GB RAM / 2 vCPUs / 60 GB SSD)
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
