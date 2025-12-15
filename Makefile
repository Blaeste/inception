# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/eschwart/data

# Colors
GREEN = \033[0;32m
RED = \033[0;31m
RESET = \033[0m

.PHONY: all build up down restart clean fclean re logs ps backup restore clean-backup url_host url_vm ftp mariadb wordpress nginx redis

# Build and start all services
all: build up

# Docker rules =================================================================
# Build all images
build:
	@echo "$(GREEN)Building Docker images...$(RESET)"
	docker compose -f $(COMPOSE_FILE) build

# Start all services
up:
	@echo "$(GREEN)Starting services...$(RESET)"
	docker compose -f $(COMPOSE_FILE) up -d

# Stop all services
down:
	@echo "$(RED)Stopping services...$(RESET)"
	docker compose -f $(COMPOSE_FILE) down

# Restart all services
restart: down up

# Show logs
logs:
	docker compose -f $(COMPOSE_FILE) logs -f

# Show running containers
ps:
	docker compose -f $(COMPOSE_FILE) ps

# MariaDB ======================================================================
# Connect to MariaDB
mariadb:
	@echo "$(GREEN)Connecting to MariaDB...$(RESET)"
	@docker exec -it mariadb mysql -u root -p

# WordPress ====================================================================
wordpress:
	@echo "$(GREEN)Connecting to WordPress container shell...$(RESET)"
	@docker exec -it wordpress bash

# NGINX ========================================================================
nginx:
	@echo "$(GREEN)Connecting to NGINX container shell...$(RESET)"
	@docker exec -it nginx sh

# Redis ========================================================================
redis:
	@echo "$(GREEN)Connecting to Redis...$(RESET)"
	@docker exec -it redis redis-cli

# FTP ==========================================================================
# Connect to FTP server (user: ftp_user)
ftp:
	@echo "$(GREEN)Connecting to FTP...$(RESET)"
	@ftp localhost 21

# WordPress save ===============================================================
# Backup save state of wordpress site
backup:
	@echo "Backing up data..."
	mkdir -p $(HOME)/inception_backup
	sudo cp -r $(DATA_DIR)/wordpress $(HOME)/inception_backup/wordpress_$(shell date +%Y%m%d_%H%M%S)
	sudo cp -r $(DATA_DIR)/mariadb $(HOME)/inception_backup/mariadb_$(shell date +%Y%m%d_%H%M%S)
	sudo chown -R $(USER):$(USER) $(HOME)/inception_backup
	@echo "$(GREEN)Backup complete!$(RESET)"

# Restore wordpress site from save
restore:
	@echo "Restoring latest backup..."
	@LATEST_WP=$$(ls -td $(HOME)/inception_backup/wordpress_* | head -1); \
	LATEST_DB=$$(ls -td $(HOME)/inception_backup/mariadb_* | head -1); \
	if [ -d "$$LATEST_WP" ] && [ -d "$$LATEST_DB" ]; then \
		sudo cp -r $$LATEST_WP/* $(DATA_DIR)/wordpress/; \
		sudo cp -r $$LATEST_DB/* $(DATA_DIR)/mariadb/; \
		echo "$(GREEN)Restore complete!$(RESET)"; \
	else \
		echo "$(RED)No backup found!$(RESET)"; \
	fi

# URL changer for defence ======================================================
# Change URL to localhost for testing with SSH tunnel (from host machine)
url_host:
	@echo "Changing URL to localhost:8443 for correction..."
	docker exec -it wordpress wp option update home 'https://localhost:8443' --allow-root
	docker exec -it wordpress wp option update siteurl 'https://localhost:8443' --allow-root
	@echo "$(GREEN)URL changed to https://localhost:8443$(RESET)"

# Change URL back to eschwart.42.fr for subject compliance
url_vm:
	@echo "Changing URL to eschwart.42.fr for subject..."
	docker exec -it wordpress wp option update home 'https://eschwart.42.fr' --allow-root
	docker exec -it wordpress wp option update siteurl 'https://eschwart.42.fr' --allow-root
	@echo "$(GREEN)URL changed to https://eschwart.42.fr$(RESET)"

# Clear backup files
clean-backup:
	@echo "$(RED)Removing all backups...$(RESET)"
	rm -rf $(HOME)/inception_backup/*
	@echo "Backups removed!"

# Classic rules ================================================================
# Clean: stop containers and remove data
clean: down
	@echo "$(RED)Removing data...$(RESET)"
	@sudo rm -rf $(DATA_DIR)/mariadb/* $(DATA_DIR)/mariadb/.[!.]* $(DATA_DIR)/mariadb/..?* 2>/dev/null || true
	@sudo rm -rf $(DATA_DIR)/wordpress/* $(DATA_DIR)/wordpress/.[!.]* $(DATA_DIR)/wordpress/..?* 2>/dev/null || true

# Full clean: remove everything (containers, images, volumes, networks)
fclean: clean
	@echo "$(RED)Removing Docker images, volumes, and networks...$(RESET)"
	docker compose -f $(COMPOSE_FILE) down -v --rmi all
	docker system prune -af

# Rebuild everything from scratch
re: fclean all
