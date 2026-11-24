#!/usr/bin/env bash
# Installe un plugin dans une version PRÉCISE, avec plusieurs stratégies de repli.
#
#   ./scripts/install-plugin.sh <slug> [version]
#
# Ordre de résolution quand une version est demandée :
#   1. Zip local  ./plugins/<slug>.<version>.zip      (le plus fiable)
#   2. wp plugin install <slug> --version=<version>   (repo WordPress.org)
#   3. Téléchargement direct depuis downloads.wordpress.org
#   4. Sinon : instructions pour récupérer la version via SVN (versions retirées)
set -euo pipefail
cd "$(dirname "$0")/.."

set -a
[ -f .env ] && . ./.env
set +a

SLUG="${1:?Usage: install-plugin.sh <slug> [version]}"
VERSION="${2:-}"

DC="docker compose"
runwp() { $DC run --rm -T wpcli wp "$@"; }

install_local_zip() {
  local zip="$1"
  echo ">> Installation depuis le zip local : $zip"
  runwp plugin install "/opt/local-plugins/$(basename "$zip")" --force --activate
}

if [ -z "$VERSION" ]; then
  echo ">> Installation de la dernière version de '$SLUG'..."
  runwp plugin install "$SLUG" --force --activate
else
  LOCAL="plugins/${SLUG}.${VERSION}.zip"
  if [ -f "$LOCAL" ]; then
    install_local_zip "$LOCAL"
  elif runwp plugin install "$SLUG" --version="$VERSION" --force --activate; then
    echo ">> Installé depuis WordPress.org."
  else
    echo ">> Version absente du repo, tentative de téléchargement direct..."
    URL="https://downloads.wordpress.org/plugin/${SLUG}.${VERSION}.zip"
    if curl -fSL "$URL" -o "$LOCAL"; then
      install_local_zip "$LOCAL"
    else
      rm -f "$LOCAL"
      cat >&2 <<EOF

!! Impossible de récupérer automatiquement '${SLUG}' ${VERSION}.
   (Fréquent : la version vulnérable a été retirée du repo.)

   Deux options :

   1) Dépose le zip toi-même :
        cp mon-plugin.zip ./plugins/${SLUG}.${VERSION}.zip
        ./scripts/install-plugin.sh ${SLUG} ${VERSION}

   2) Reconstruis-le depuis le tag SVN (les tags restent accessibles) :
        svn export https://plugins.svn.wordpress.org/${SLUG}/tags/${VERSION}/ /tmp/${SLUG}
        (cd /tmp && zip -r ${SLUG}.${VERSION}.zip ${SLUG})
        cp /tmp/${SLUG}.${VERSION}.zip ./plugins/
        ./scripts/install-plugin.sh ${SLUG} ${VERSION}
EOF
      exit 1
    fi
  fi
fi

echo -n ">> Version installée de ${SLUG} : "
runwp plugin get "$SLUG" --field=version
