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
