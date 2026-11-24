# Lab Joomla "toutes versions" (build depuis l'archive officielle)
NAME      ?= joomla-build
HTTP_PORT ?= 8080

export COMPOSE_PROJECT_NAME := $(NAME)
export HTTP_PORT

.DEFAULT_GOAL := help

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	 awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-20s\033[0m %s\n",$$1,$$2}'

up: ## Construit l'image et demarre le lab
	docker compose up -d --build
	./scripts/provision.sh

shell: ## Ouvre un shell dans le conteneur Joomla
	docker compose exec joomla bash

logs: ## Affiche les logs en continu
	docker compose logs -f joomla

reset: ## Efface les volumes et reinstalle la version courante
	docker compose down -v
	docker compose up -d --build
	./scripts/provision.sh

down: ## Arrete les conteneurs (conserve les donnees)
	docker compose down

clean: ## Supprime conteneurs + volumes
	docker compose down -v

.PHONY: help up shell logs reset down clean
