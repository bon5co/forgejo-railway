#!/bin/sh
# Forgejo for Railway: validate the variables, point the forge at Railway's port and domain, then hand over to the
# upstream entrypoint (which writes app.ini on first boot, applies GITEA__section__KEY on every boot and starts s6).
set -eu

fail() { echo "railway-entrypoint: $*" >&2; exit 1; }

P="${FORGEJO_ADMIN_PASSWORD:-}"
[ "${#P}" -ge 16 ] || fail "FORGEJO_ADMIN_PASSWORD is required (16 characters or more)"
[ -n "${SECRET_KEY:-}" ] && [ "${#SECRET_KEY}" -ge 32 ] || fail "SECRET_KEY is required (32 characters or more)"
case "$FORGEJO_ADMIN_USER" in *[!A-Za-z0-9._-]*|"") fail "FORGEJO_ADMIN_USER may contain letters, digits, dot, dash and underscore only" ;; esac

PORT="${PORT:-3000}"
if [ -z "${ROOT_URL:-}" ]; then
  [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ] || fail "RAILWAY_PUBLIC_DOMAIN is empty: give the service a domain, or set ROOT_URL"
  ROOT_URL="https://${RAILWAY_PUBLIC_DOMAIN}/"
fi
DOMAIN_FROM_URL=$(echo "$ROOT_URL" | sed -E 's#^[a-z]+://([^/:]+).*#\1#')

export HTTP_PORT="$PORT" ROOT_URL DOMAIN="$DOMAIN_FROM_URL" SSH_DOMAIN="$DOMAIN_FROM_URL" INSTALL_LOCK=true
# app.ini is written once from the variables above; these are re-applied to it on every boot, so a changed domain or
# port follows the deploy instead of the first one.
export GITEA__server__HTTP_PORT="$PORT"
export GITEA__server__ROOT_URL="$ROOT_URL"
export GITEA__server__DOMAIN="$DOMAIN_FROM_URL"
export GITEA__server__SSH_DOMAIN="$DOMAIN_FROM_URL"
export GITEA__server__DISABLE_SSH=true
export GITEA__security__INSTALL_LOCK=true
export GITEA__service__DISABLE_REGISTRATION=true
export GITEA__service__REQUIRE_SIGNIN_VIEW="${REQUIRE_SIGNIN_VIEW:-false}"
export GITEA__repository__DEFAULT_PRIVATE="${DEFAULT_PRIVATE:-private}"
export GITEA__server__LFS_START_SERVER=true
export GITEA__log__MODE=console
export GITEA__other__SHOW_FOOTER_VERSION=false

echo "railway-entrypoint: port=$PORT root_url=$ROOT_URL admin=$FORGEJO_ADMIN_USER owner=$(stat -c %u:%g /data 2>/dev/null || echo ?)"
exec /usr/bin/entrypoint "$@"
