# Lab GitLab CE pour PoC de vulnérabilités
#
# Instances nommées + ports distincts pour plusieurs labs en parallèle :
#   make up NAME=gitlab-14 HTTP_PORT=8081

NAME      ?= gitlabvuln
HTTP_PORT ?= 8080
SSH_PORT  ?= 2222

export COMPOSE_PROJECT_NAME := $(NAME)
export HTTP_PORT
export SSH_PORT

.DEFAULT_GOAL := help

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	 awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-20s\033[0m %s\n",$$1,$$2}'

up: ## Démarre le lab (premier lancement : 5 à 10 minutes)
	docker compose up -d
	./scripts/provision.sh

root-password: ## Affiche le mot de passe root courant
	@docker compose exec gitlab cat /etc/gitlab/initial_root_password 2>/dev/null \
	  | grep "^Password:" | awk '{print $$2}' \
	  || echo "(fichier expiré — changez le mdp via l'interface web)"

gitlab-cli: ## Lance gitlab-rails console (debug avancé)
	docker compose exec -it gitlab gitlab-rails console

reconfigure: ## Recharge la configuration GitLab (après modif du compose)
	docker compose exec gitlab gitlab-ctl reconfigure

shell: ## Ouvre un shell dans le conteneur GitLab
	docker compose exec gitlab bash

logs: ## Affiche les logs GitLab en temps réel
	docker compose logs -f gitlab

reset: ## Remet le lab à zéro (supprime tous les volumes)
	docker compose down -v
	docker compose up -d
	./scripts/provision.sh

down: ## Arrête le conteneur (conserve les données)
	docker compose down

clean: ## Supprime conteneur + volumes (tout est effacé)
	docker compose down -v

.PHONY: help up root-password gitlab-cli reconfigure shell logs reset down clean
