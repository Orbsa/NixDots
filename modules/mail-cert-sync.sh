#!/usr/bin/env bash
# Sync mail.orbsa.net's TLS certificate from the NPMplus proxy to poste.io on Unraid.
#
# Why this exists
#   The proxy (10.0.0.3) owns this certificate, and it is issued with a Cloudflare
#   DNS-01 challenge on purpose: the firewall DNATs ports 80/443 to the proxy, so
#   poste (10.0.0.5) can never answer an HTTP-01 challenge itself. That is exactly
#   what broke poste's built-in renewal and let the old certificate expire in
#   August 2026 while its daily `poste le:renew` cron failed silently.
#   poste terminates SMTP/IMAP/POP3/Sieve, which a reverse proxy cannot serve, so
#   the same key material has to exist on the mail host as well.
#
# How the material is laid out
#   poste's /etc/cont-init.d/21-certificate.sh is the source of truth, and this
#   script reproduces it so that a renewal does not require restarting the whole
#   mail server:
#     /data/ssl/{server.crt,server.key,ca.crt}     (Unraid bind mount of /mnt/user/poste/ssl)
#       -> /etc/ssl/{server.crt,server.key,ca.crt} (what nginx reads)
#       -> /etc/ssl/server-combined.crt = server.crt + ca.crt (what dovecot reads)
#       -> /opt/haraka-*/config/tls_{cert,key}.pem are symlinks to the above
#   If poste ever changes that layout, `docker restart poste` on the Unraid host is
#   the fallback: its own init script redoes all of the above from /data/ssl.
#
# Timing
#   The certificate is short-lived (~6 days, Let's Encrypt "shortlived" profile and
#   ARI-driven renewal), so poste's copy goes stale within days of any renewal this
#   misses. CERT_ID is the NPMplus certificate id; its lineage lives at
#   /data/tls/certbot/live/npm-<CERT_ID> inside the npmplus container.

set -euo pipefail

CERT_NAME="npm-${CERT_ID:?CERT_ID must be set to the NPMplus certificate id}"
LIVE="/data/tls/certbot/live/${CERT_NAME}"
POSTE_SSL="/mnt/user/poste/ssl"
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15)

log() { printf '%s %s\n' "$(date -Is)" "$*"; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

log "fetching ${CERT_NAME} from the proxy"
ssh "${SSH_OPTS[@]}" proxy docker exec npmplus cat "${LIVE}/fullchain.pem" > "${work}/server.crt"
ssh "${SSH_OPTS[@]}" proxy docker exec npmplus cat "${LIVE}/privkey.pem" > "${work}/server.key"
ssh "${SSH_OPTS[@]}" proxy docker exec npmplus cat "${LIVE}/chain.pem" > "${work}/ca.crt"

# Never install a mismatched pair: it would break TLS on every mail port at once,
# including the hop the VIX relay delivers over.
openssl x509 -in "${work}/server.crt" -noout -pubkey > "${work}/cert.pub"
openssl pkey -in "${work}/server.key" -pubout > "${work}/key.pub"
if ! cmp -s "${work}/cert.pub" "${work}/key.pub"; then
  log "FATAL: fetched certificate and private key do not match — leaving poste untouched"
  exit 1
fi

local_hash="$(sha256sum "${work}/server.crt" | cut -d' ' -f1)"
remote_hash="$(ssh "${SSH_OPTS[@]}" unraid sha256sum "${POSTE_SSL}/server.crt" | cut -d' ' -f1)"

if [ "${local_hash}" = "${remote_hash}" ]; then
  log "poste already has the current certificate; nothing to do"
  exit 0
fi

log "installing new certificate (poste has ${remote_hash:0:16}, proxy has ${local_hash:0:16})"
stamp="$(date +%Y%m%d%H%M%S)"
ssh "${SSH_OPTS[@]}" unraid cp -a "${POSTE_SSL}/server.crt" "${POSTE_SSL}/server.crt.bak-${stamp}"
ssh "${SSH_OPTS[@]}" unraid cp -a "${POSTE_SSL}/server.key" "${POSTE_SSL}/server.key.bak-${stamp}"
ssh "${SSH_OPTS[@]}" unraid cp -a "${POSTE_SSL}/ca.crt" "${POSTE_SSL}/ca.crt.bak-${stamp}"

tar -C "${work}" -cf - server.crt server.key ca.crt \
  | ssh "${SSH_OPTS[@]}" unraid tar -C "${POSTE_SSL}" -xf -

# 8:mem is the ownership poste's own init script leaves on these files.
ssh "${SSH_OPTS[@]}" unraid chown 8:mem "${POSTE_SSL}/server.crt" "${POSTE_SSL}/server.key" "${POSTE_SSL}/ca.crt"
ssh "${SSH_OPTS[@]}" unraid chmod 644 "${POSTE_SSL}/server.crt" "${POSTE_SSL}/server.key" "${POSTE_SSL}/ca.crt"

log "propagating into poste and restarting the TLS services"
ssh "${SSH_OPTS[@]}" unraid 'set -e
docker exec poste cp /data/ssl/ca.crt /etc/ssl/ca.crt
docker exec poste cp /data/ssl/server.crt /etc/ssl/server.crt
docker exec poste cp /data/ssl/server.key /etc/ssl/server.key
docker exec poste chown root:mail /etc/ssl/server.key
docker exec poste chmod 640 /etc/ssl/server.key
docker exec poste cp /data/ssl/server.crt /etc/ssl/server-combined.crt
docker exec poste sh -c "echo >> /etc/ssl/server-combined.crt"
docker exec poste sh -c "cat /data/ssl/ca.crt >> /etc/ssl/server-combined.crt"
docker exec poste s6-svc -r /var/run/s6/services/nginx
docker exec poste s6-svc -r /var/run/s6/services/dovecot
docker exec poste s6-svc -r /var/run/s6/services/haraka-smtp
docker exec poste s6-svc -r /var/run/s6/services/haraka-submission'

log "done — poste now serves ${local_hash:0:16}"
