# Lab Joomla — image officielle (5.x / 6.x)
NAME      ?= joomlavuln
HTTP_PORT ?= 8080

export COMPOSE_PROJECT_NAME := $(NAME)
export HTTP_PORT

.DEFAULT_GOAL := help

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	 awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-20s\033[0m %s\n",$$1,$$2}'

up: ## Démarre le lab (Joomla s'installe automatiquement)
	docker compose up -d
	./scripts/provision.sh

ext: ## Installe une extension : make ext EXT=<chemin.zip ou URL>
	./scripts/install-extension.sh $(EXT)

shell: ## Ouvre un shell dans le conteneur Joomla
	docker compose exec joomla bash

logs: ## Affiche les logs Joomla en continu
	docker compose logs -f joomla

reset: ## Réinitialise le lab (état 100 % propre)
	docker compose down -v
	docker compose up -d
	./scripts/provision.sh

down: ## Arrête les conteneurs (conserve les données)
	docker compose down

clean: ## Supprime conteneurs + volumes
	docker compose down -v

.PHONY: help up ext shell logs reset down clean
