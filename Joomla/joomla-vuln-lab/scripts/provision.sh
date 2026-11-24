#!/usr/bin/env bash
# Attend que l'auto-installation de Joomla soit terminee.
# Detecte les erreurs de l'entrypoint (ex: mot de passe trop court) et
# les affiche immediatement plutot que de boucler jusqu'au timeout.
set -euo pipefail
cd "$(dirname "$0")/.."

set -a
[ -f .env ] && . ./.env
set +a

DC="docker compose"
HOSTPORT="$($DC port joomla 80 2>/dev/null | sed 's/.*://')"
HOSTPORT="${HOSTPORT:-${HTTP_PORT:-8080}}"
URL="http://localhost:${HOSTPORT}"

echo ">> Attente de l'auto-installation de Joomla (peut prendre 2-3 min)..."
tries=0
while true; do
  tries=$((tries + 1))
  if [ "$tries" -gt 120 ]; then
    echo ""
    echo "!! Timeout. Voir 'make logs' pour le detail." >&2
    exit 1
  fi

  # Detecter les erreurs connues dans les logs du conteneur
  ERRORS=$($DC logs --no-log-prefix joomla 2>/dev/null | grep -i "\[ERROR\]" || true)
  if [ -n "$ERRORS" ]; then
    echo ""
    echo "!! L'entrypoint Joomla a signale une erreur :"
    echo "$ERRORS"
    echo ""
    echo "Causes frequentes :"
    echo "  - JOOMLA_ADMIN_PASSWORD trop court (Joomla 6.x : > 12 caracteres)"
    echo "  - Verifiez votre .env puis relancez 'make reset'"
    exit 1
  fi

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null || true)

  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    LOCATION=$(curl -s -o /dev/null -w "%{url_effective}" -L "$URL" 2>/dev/null || true)
    if echo "$LOCATION" | grep -qi "installation"; then
      echo -n "."
    else
      echo ""
      echo ">> Installation terminee."
      break
    fi
  else
    echo -n "."
  fi

  sleep 3
done

echo ""
echo "======================================================"
echo " Joomla ${JOOMLA_TAG:-latest} pret : ${URL}"
echo " Admin : ${URL}/administrator"
echo " Login : ${JOOMLA_ADMIN_USERNAME:-admin} / ${JOOMLA_ADMIN_PASSWORD:-Admin@VulnLab1}"
echo "======================================================"
