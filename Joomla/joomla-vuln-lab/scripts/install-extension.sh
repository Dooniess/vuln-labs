#!/usr/bin/env bash
# Installe une extension Joomla depuis un zip local ou une URL.
# Usage :
#   ./scripts/install-extension.sh <chemin-local.zip>
#   ./scripts/install-extension.sh <https://example.com/ext.zip>
#
# Pour les installations permanentes, préférez JOOMLA_EXTENSIONS_PATHS
# ou JOOMLA_EXTENSIONS_URLS dans le .env (appliquées à chaque make reset).
set -euo pipefail
cd "$(dirname "$0")/.."

set -a
[ -f .env ] && . ./.env
set +a

TARGET="${1:?Usage: install-extension.sh <zip-local-ou-url>}"
DC="docker compose"

if [[ "$TARGET" == http* ]]; then
  echo ">> Installation depuis URL : $TARGET"
  docker compose exec -T joomla php /var/www/html/cli/joomla.php extension:install \
    --url="$TARGET"
else
  if [ ! -f "$TARGET" ]; then
    echo "!! Fichier introuvable : $TARGET" >&2
    exit 1
  fi
  BASENAME="$(basename "$TARGET")"
  echo ">> Copie de $BASENAME dans le conteneur..."
  docker compose cp "$TARGET" "joomla:/tmp/$BASENAME"
  echo ">> Installation..."
  docker compose exec -T joomla php /var/www/html/cli/joomla.php extension:install \
    --path="/tmp/$BASENAME"
fi
echo ">> Installation terminée."
