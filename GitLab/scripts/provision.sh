#!/usr/bin/env bash
# Attend que GitLab soit opérationnel via HTTP, puis affiche les accès.
#
# Approche : HTTP polling plutôt que parsing de logs.
# Avantage : fonctionne quelle que soit la version de GitLab / Cinc / Chef.
# GitLab retourne 502 pendant l'init, puis 302 vers la page de login quand il est prêt.
#
# Le premier démarrage peut prendre 5 à 10 minutes.
set -euo pipefail
cd "$(dirname "$0")/.."

set -a
[ -f .env ] && . ./.env
set +a

DC="docker compose"
HOSTPORT="${HTTP_PORT:-8080}"
URL="http://localhost:${HOSTPORT}"

echo ">> Démarrage de GitLab ${GITLAB_TAG:-latest}..."
echo "   Premier lancement : 5 à 10 minutes (initialisation Omnibus)."
echo "   Progression en temps réel : make logs"
echo ""
echo -n ">> Attente que GitLab soit opérationnel "

tries=0
while true; do
  tries=$((tries + 1))
  if [ "$tries" -gt 180 ]; then
    echo ""
    echo "!! Timeout (15 min). GitLab n'a pas terminé son démarrage." >&2
    echo "   → Vérifiez la mémoire Docker Desktop (minimum 6 GB)." >&2
    echo "   → Consultez les logs : make logs" >&2
    exit 1
  fi

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null || echo "000")

  case "$HTTP_CODE" in
    200|301|302|303)
      echo ""
      echo ">> GitLab opérationnel (HTTP $HTTP_CODE)."
      break
      ;;
    502|000|"")
      # 502 = nginx up mais Rails pas encore prêt
      # 000 = pas encore de connexion possible
      echo -n "."
      ;;
    *)
      echo -n "[$HTTP_CODE]"
      ;;
  esac

  sleep 5
done

# Récupérer le mot de passe root initial (valable 24h après la 1ère install)
ROOT_PASSWORD=$($DC exec -T gitlab \
  cat /etc/gitlab/initial_root_password 2>/dev/null \
  | grep "^Password:" | awk '{print $2}' || true)

if [ -z "$ROOT_PASSWORD" ]; then
  ROOT_PASSWORD="(fichier absent ou expiré — utilisez 'make root-password')"
fi

echo ""
echo "======================================================"
echo " GitLab ${GITLAB_TAG:-latest} prêt : ${URL}"
echo ""
echo " Compte root :"
echo "   Login    : root"
echo "   Password : ${ROOT_PASSWORD}"
echo ""
echo " ⚠️  Le mot de passe initial expire après 24h."
echo "    Changez-le : ${URL}/-/user_settings/password/edit"
echo "======================================================"
