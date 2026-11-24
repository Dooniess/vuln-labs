# Lab WordPress pour PoC de vulnérabilités
#
# Instance nommée + port (pour lancer plusieurs labs en parallèle) :
#   make up NAME=lab-cve1234 HTTP_PORT=8081

NAME      ?= wpvuln
HTTP_PORT ?= 8080

export COMPOSE_PROJECT_NAME := $(NAME)
export HTTP_PORT

.DEFAULT_GOAL := help

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	 awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n",$$1,$$2}'

up: ## Démarre le lab et installe WordPress
	docker compose up -d db wordpress
	./scripts/provision.sh

plugin: ## Installe un plugin : make plugin SLUG=<slug> VERSION=<x.y.z>
	./scripts/install-plugin.sh $(SLUG) $(VERSION)

wp: ## Commande WP-CLI arbitraire : make wp CMD="plugin list"
	docker compose run --rm -T wpcli wp $(CMD)

shell: ## Shell root dans le conteneur WordPress
	docker compose exec wordpress bash

logs: ## Suit les logs WordPress (Ctrl-C pour quitter)
	docker compose logs -f wordpress

reset: ## Remet le lab à zéro (état propre, même port)
	docker compose down -v
	docker compose up -d db wordpress
	./scripts/provision.sh

down: ## Arrête le lab (conserve les données)
	docker compose down

clean: ## Supprime conteneurs ET volumes (tout est effacé)
	docker compose down -v

.PHONY: help up plugin wp shell logs reset down clean
