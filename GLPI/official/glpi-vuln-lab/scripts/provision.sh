#!/usr/bin/env bash
# GLPI s'auto-installe via l'entrypoint de l'image officielle.
# Ce script attend simplement que le service réponde, puis affiche les accès.
set -euo pipefail
cd "$(dirname "$0")/.."

set -a
[ -f .env ] && . ./.env
set +a

DC="docker compose"

# Port réellement mappé (robuste si on override HTTP_PORT)
HOSTPORT="$($DC port glpi 80 2>/dev/null | sed 's/.*://')"
HOSTPORT="${HOSTPORT:-${HTTP_PORT:-8080}}"
URL="http://localhost:${HOSTPORT}"

echo ">> Attente de l'installation automatique de GLPI"
echo "   (le 1er démarrage peut prendre 1 à 2 minutes, le temps de créer le schéma)..."
tries=0
until curl -fsS -o /dev/null "$URL"; do
  tries=$((tries + 1))
  if [ "$tries" -gt 90 ]; then
    echo "!! Timeout : GLPI ne répond pas. Regarde 'make logs'." >&2
    exit 1
  fi
  sleep 2
done

cat <<EOF

======================================================
 GLPI prêt : ${URL}

 Comptes par défaut (identifiant / mot de passe) :
   glpi / glpi            -> super-administrateur
   tech / tech            -> technicien
   normal / normal        -> utilisateur standard
   post-only / postonly   -> self-service
======================================================
 Note : ces comptes par défaut existent sur toute install fraîche.
 En production c'est un vecteur connu ; en lab, c'est pratique pour tester.
EOF
