#!/usr/bin/env bash
# Installe GLPI via bin/console si ce n'est pas déjà fait.
# L'install est lancée en tant que www-data pour que les fichiers de config
# soient lisibles par Apache.
set -euo pipefail
cd "$(dirname "$0")/.."

set -a
[ -f .env ] && . ./.env
set +a

DC="docker compose"

echo ">> Attente du conteneur GLPI..."
tries=0
until $DC exec -T glpi php -v >/dev/null 2>&1; do
  tries=$((tries + 1))
  if [ "$tries" -gt 60 ]; then
    echo "!! Timeout : le conteneur GLPI ne répond pas. Voir 'make logs'." >&2
    exit 1
  fi
  sleep 2
done

if $DC exec -T -u www-data glpi test -f /var/www/html/config/config_db.php; then
  echo ">> GLPI est déjà installé."
else
  echo ">> Installation de GLPI ${GLPI_VERSION} via bin/console..."
  $DC exec -T -u www-data glpi php /var/www/html/bin/console db:install \
    --db-host=db --db-port=3306 \
    --db-name="${GLPI_DB_NAME:-glpi}" \
    --db-user="${GLPI_DB_USER:-glpi}" \
    --db-password="${GLPI_DB_PASSWORD:-glpi}" \
    --no-interaction --force
fi

HOSTPORT="$($DC port glpi 80 2>/dev/null | sed 's/.*://')"
HOSTPORT="${HOSTPORT:-${HTTP_PORT:-8080}}"
URL="http://localhost:${HOSTPORT}"

cat <<EOF

======================================================
 GLPI ${GLPI_VERSION} prêt : ${URL}

 Comptes par défaut (identifiant / mot de passe) :
   glpi / glpi            -> super-administrateur
   tech / tech            -> technicien
   normal / normal        -> utilisateur standard
   post-only / postonly   -> self-service
======================================================
 Rappel : sur une install fraîche, GLPI signale que le dossier install/
 devrait être supprimé. En lab, tu peux l'ignorer.
EOF
