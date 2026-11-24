# Lab GLPI "toutes versions" (build depuis l'archive officielle)
#
# Changer de version = éditer GLPI_VERSION dans .env puis 'make reset'.
# Override ponctuel possible :  GLPI_VERSION=10.0.6 PHP_VERSION=8.1 make reset

NAME      ?= glpibuild
HTTP_PORT ?= 8080

export COMPOSE_PROJECT_NAME := $(NAME)
export HTTP_PORT

.DEFAULT_GOAL := help

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	 awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n",$$1,$$2}'

up: ## Construit l'image et démarre le lab, puis installe GLPI
	docker compose up -d --build
	./scripts/provision.sh

console: ## Commande GLPI console : make console CMD="list"
	docker compose exec -T -u www-data glpi php /var/www/html/bin/console $(CMD)

shell: ## Ouvre un shell dans le conteneur GLPI
	docker compose exec glpi bash

logs: ## Affiche les logs GLPI en continu
	docker compose logs -f glpi

reset: ## Réinitialise (efface les volumes) et réinstalle la version courante
	docker compose down -v
	docker compose up -d --build
	./scripts/provision.sh

down: ## Arrête le lab (conserve les données)
	docker compose down

clean: ## Supprime conteneurs + volumes
	docker compose down -v

.PHONY: help up console shell logs reset down clean
