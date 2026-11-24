# Lab GLPI pour PoC de vulnérabilités
#
# Instance nommée + port (plusieurs labs en parallèle) :
#   make up NAME=glpi-11 HTTP_PORT=8081

NAME      ?= glpivuln
HTTP_PORT ?= 8080

export COMPOSE_PROJECT_NAME := $(NAME)
export HTTP_PORT

.DEFAULT_GOAL := help

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	 awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n",$$1,$$2}'

up: ## Démarre le lab (GLPI s'installe automatiquement)
	docker compose up -d
	./scripts/provision.sh

console: ## Commande GLPI console : make console CMD="list"
	docker compose exec -T glpi php /var/www/glpi/bin/console $(CMD)

timezones: ## Active le support des fuseaux horaires (optionnel)
	docker compose exec -T db mariadb -uroot -p"$${DB_ROOT_PASSWORD:-root}" \
	  -e "GRANT SELECT ON mysql.time_zone_name TO '$${GLPI_DB_USER:-glpi}'@'%'; FLUSH PRIVILEGES;"
	docker compose exec -T glpi php /var/www/glpi/bin/console database:enable_timezones

shell: ## Ouvre un shell dans le conteneur GLPI
	docker compose exec glpi bash

logs: ## Affiche les logs GLPI en continu
	docker compose logs -f glpi

reset: ## Réinitialise le lab (état propre, réinstalle GLPI)
	docker compose down -v
	docker compose up -d
	./scripts/provision.sh

down: ## Arrête le lab (conserve les données)
	docker compose down

clean: ## Supprime conteneurs + volumes
	docker compose down -v

.PHONY: help up console timezones shell logs reset down clean
