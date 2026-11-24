#!/usr/bin/env bash
# Provisionne WordPress (install du core) une fois les conteneurs démarrés,
# puis personnalise l'article par défaut si LAB_NOTE est défini dans .env.
set -euo pipefail
cd "$(dirname "$0")/.."

# Charge les variables depuis .env
set -a
[ -f .env ] && . ./.env
set +a

DC="docker compose"
runwp() { $DC run --rm -T wpcli wp "$@"; }

echo ">> Attente de WordPress + base de données..."
tries=0
until runwp core version >/dev/null 2>&1; do
  tries=$((tries + 1))
  if [ "$tries" -gt 60 ]; then
    echo "!! Timeout : WordPress n'est pas prêt. Vérifie 'docker compose logs'." >&2
    exit 1
  fi
  sleep 2
done

# Récupère le port réellement mappé (robuste si on override HTTP_PORT)
HOSTPORT="$($DC port wordpress 80 2>/dev/null | sed 's/.*://')"
HOSTPORT="${HOSTPORT:-${HTTP_PORT:-8080}}"
URL="http://localhost:${HOSTPORT}"

if runwp core is-installed >/dev/null 2>&1; then
  echo ">> WordPress est déjà installé."
else
  echo ">> Installation de WordPress sur ${URL} ..."
  runwp core install \
    --url="$URL" \
    --title="${WP_TITLE:-Vuln Lab}" \
    --admin_user="${WP_ADMIN_USER:-admin}" \
    --admin_password="${WP_ADMIN_PASSWORD:-admin}" \
    --admin_email="${WP_ADMIN_EMAIL:-admin@example.test}" \
    --skip-email
fi

# --- Personnalisation de l'article par défaut (ID 1) --------------------
# Ajoute LAB_NOTE en fin de l'article par défaut, s'il est défini.
if [ -n "${LAB_NOTE:-}" ]; then
  echo ">> Ajout de la note à l'article par défaut..."
  CURRENT="$(runwp post get 1 --field=post_content 2>/dev/null || true)"
  runwp post update 1 --post_content="${CURRENT}
<!-- wp:paragraph --><p><strong>${LAB_NOTE}</strong></p><!-- /wp:paragraph -->" >/dev/null \
    && echo "   Note ajoutée : \"${LAB_NOTE}\""
fi

cat <<EOF

======================================================
 Lab prêt   : ${URL}
 Admin      : ${URL}/wp-admin
 Login      : ${WP_ADMIN_USER:-admin} / ${WP_ADMIN_PASSWORD:-admin}
======================================================
EOF
