# Variables
NAME 			:= inception
DOCKER_COMPOSE_FILE := srcs/docker-compose.yml
COMPOSE 		:= docker compose -p $(NAME) -f $(DOCKER_COMPOSE_FILE)

# Colors
GREEN 			:= \033[0;32m
YELLOW 			:= \033[0;33m
RED 			:= \033[0;31m
RESET 			:= \033[0m

# HELP
.DEFAULT_GOAL := help
help:
	@echo "$(GREEN)=== Inception Makefile ===$(RESET)"
	@echo ""
	@echo "$(GREEN)MAIN TARGETS:$(RESET)"
	@echo "  make up              Start services in background"
	@echo "  make down            Stop services"
	@echo "  make restart         Restart services"
	@echo "  make re              Full rebuild (clean + up)"
	@echo ""
	@echo "$(GREEN)UTILITIES:$(RESET)"
	@echo "  make ps              Show container status"
	@echo "  make logs            View logs (follow mode)"
	@echo "  make shell           Open shell in running container"
	@echo "  make build           Build images without starting"
	@echo "  make clean           Remove containers and networks"
	@echo "  make fclean          Full clean (volumes + images)"
	@echo "  make help            Show this help message"
	@echo ""

# CHECKS=
check-docker:
	@which docker > /dev/null || (echo "$(RED)Docker not installed$(RESET)" && exit 1)
	@docker compose version > /dev/null || (echo "$(RED)Docker Compose not installed$(RESET)" && exit 1)

# CREATE VOLUMES
create-volumes:
	@echo "$(GREEN)Creating volume directories...$(RESET)"
	@mkdir -p /home/emalungo/data/mariadb
	@echo "$(GREEN)Volumes created successfully$(RESET)"

# BUILD & START
up: check-docker create-volumes
	@echo "$(GREEN)Starting $(NAME)...$(RESET)"
	@$(COMPOSE) up -d --build

build: check-docker
	@echo "$(GREEN)Building images...$(RESET)"
	@$(COMPOSE) build --no-cache

# STOP
down: check-docker
	@echo "$(YELLOW)Stopping $(NAME)...$(RESET)"
	@$(COMPOSE) down

# RESTART
restart: down up
	@echo "$(GREEN)Restart complete$(RESET)"

# STATUS
ps: check-docker
	@$(COMPOSE) ps

# LOGS
logs: check-docker
	@$(COMPOSE) logs -f

# SHELL ACCESS
shell: check-docker
	@read -p "Enter service name: " service; \
	$(COMPOSE) exec $$service /bin/bash

# CLEAN (containers + networks)
clean: check-docker
	@echo "$(YELLOW)Cleaning containers and networks...$(RESET)"
	@$(COMPOSE) down --remove-orphans

# FULL CLEAN (volumes + images)
fclean: check-docker
	@echo "$(RED)Full clean (volumes + images + orphans)...$(RESET)"
	@$(COMPOSE) down -v --rmi all --remove-orphans

# REBUILD
re: fclean up
	@echo "$(GREEN)Rebuild complete$(RESET)"

# PHONY TARGETS
.PHONY: all help check-docker create-volumes up build down restart ps logs shell clean fclean re