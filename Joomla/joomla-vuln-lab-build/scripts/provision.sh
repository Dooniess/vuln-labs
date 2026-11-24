#!/usr/bin/env bash
# Installe Joomla via CLI pour les versions 4.3.x et 4.4.x.
# Pour 3.x, 4.0.x, 4.1.x, 4.2.x : pas de CLI, affiche les parametres du wizard.
set -euo pipefail
cd "$(dirname "$0")/.."

set -a
[ -f .env ] && . ./.env
set +a

DC="docker compose"
JOOMLA_VERSION="${JOOMLA_VERSION:-}"
MAJOR=$(echo "$JOOMLA_VERSION" | cut -d. -f1)
MINOR=$(echo "$JOOMLA_VERSION" | cut -d. -f2)

HOSTPORT="$($DC port joomla 80 2>/dev/null | sed 's/.*://')"
HOSTPORT="${HOSTPORT:-${HTTP_PORT:-8080}}"
URL="http://localhost:${HOSTPORT}"

echo ">> Attente du conteneur Joomla ${JOOMLA_VERSION}..."
tries=0
until $DC exec -T joomla php -v >/dev/null 2>&1; do
  tries=$((tries + 1))
  if [ "$tries" -gt 60 ]; then
    echo "!! Timeout : le conteneur ne repond pas. Voir 'make logs'." >&2
    exit 1
  fi
  sleep 2
done

# CLI disponible a partir de Joomla 4.3.0 uniquement
CLI_AVAILABLE=false
if [ "$MAJOR" -eq 4 ] && [ "$MINOR" -ge 3 ]; then
  CLI_AVAILABLE=true
fi

if $CLI_AVAILABLE; then
  if $DC exec -T joomla test -f /var/www/html/configuration.php 2>/dev/null; then
    echo ">> Joomla ${JOOMLA_VERSION} est deja installe."
  else
    echo ">> Installation de Joomla ${JOOMLA_VERSION} via CLI..."
    $DC exec -T -u www-data joomla php /var/www/html/installation/joomla.php install \
      --site-name="${JOOMLA_SITE_NAME:-Vuln Lab}" \
      --admin-user="${JOOMLA_ADMIN_USER:-Admin}" \
      --admin-username="${JOOMLA_ADMIN_USERNAME:-admin}" \
      --admin-password="${JOOMLA_ADMIN_PASSWORD:-Admin@VulnLab1}" \
      --admin-email="${JOOMLA_ADMIN_EMAIL:-admin@example.test}" \
      --db-type=mysqli \
      --db-host=db \
      --db-user="${JOOMLA_DB_USER:-joomla}" \
      --db-pass="${JOOMLA_DB_PASSWORD:-joomla}" \
      --db-name="${JOOMLA_DB_NAME:-joomla}" \
      --no-interaction
    $DC exec -T joomla rm -rf /var/www/html/installation
    echo ">> Dossier installation/ supprime."
  fi
  echo ""
  echo "======================================================"
  echo " Joomla ${JOOMLA_VERSION} pret : ${URL}"
  echo " Admin  : ${URL}/administrator"
  echo " Login  : ${JOOMLA_ADMIN_USERNAME:-admin} / ${JOOMLA_ADMIN_PASSWORD:-Admin@VulnLab1}"
  echo "======================================================"

else
  echo ""
  echo "======================================================"
  echo " Joomla ${JOOMLA_VERSION} demarre : ${URL}"
  echo ""
  echo " Cette version n'a pas de CLI d'installation."
  echo " Completez le wizard dans votre navigateur :"
  echo "   ${URL}/installation/"
  echo ""
  echo " Parametres BDD a saisir dans le wizard :"
  echo "   Type BDD      : MySQLi"
  echo "   Hote BDD      : db   <- important, pas localhost"
  echo "   Utilisateur   : ${JOOMLA_DB_USER:-joomla}"
  echo "   Mot de passe  : ${JOOMLA_DB_PASSWORD:-joomla}"
  echo "   Nom BDD       : ${JOOMLA_DB_NAME:-joomla}"
  echo "======================================================"
fi
