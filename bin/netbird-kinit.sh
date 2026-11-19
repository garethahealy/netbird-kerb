#!/bin/zsh
set -euo pipefail

KERB_USER="${KERB_USER:-$USER}"
KERB_REALM="${KERB_REALM:-IPA.REDHAT.COM}"
KERB_PRINCIPAL="${KERB_PRINCIPAL:-${KERB_USER}@${KERB_REALM}}"
KERB_KEYTAB="${KERB_KEYTAB:-$HOME/.kerberos.${KERB_USER}.keytab}"
KERB_CCACHE="${KERB_CCACHE:-$HOME/.krb5cc_${KERB_USER}}"

export PATH="/opt/homebrew/bin:/opt/homebrew/opt/krb5/bin:/usr/local/bin:/usr/bin:/bin"
export KRB5_KTNAME="FILE:$KERB_KEYTAB"
export KRB5CCNAME="FILE:$KERB_CCACHE"

CACHE="$HOME/.cache"
STATE="$CACHE/netbird-kinit.state"
LAST="$CACHE/netbird-kinit.last-date"
LOG="$CACHE/netbird-kinit.log"
mkdir -p "$CACHE"

log() {
  print -r -- "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

if ! command -v netbird >/dev/null; then
  log "netbird is not installed"
  exit 1
fi

if ! command -v jq >/dev/null; then
  log "jq is not installed"
  exit 1
fi

connected=0
if netbird status --json 2>/dev/null | jq -e '.daemonStatus == "Connected"' >/dev/null; then
  connected=1
fi

prev=0
[[ -f "$STATE" ]] && prev="$(<"$STATE")"
print -r -- "$connected" > "$STATE"

# Only act while NetBird is up
if (( connected == 0 )); then
  exit 0
fi

today="$(date +%Y-%m-%d)"
last_date=""
[[ -f "$LAST" ]] && last_date="$(<"$LAST")"

ticket_ok=0
if klist -s >/dev/null 2>&1; then
  ticket_ok=1
fi

# kinit on: connect transition, expired ticket, or first run of the day
if (( prev == 0 )) || (( ticket_ok == 0 )) || [[ "$last_date" != "$today" ]]; then
  if kinit -t "$KERB_KEYTAB" -k "$KERB_PRINCIPAL"; then
    print -r -- "$today" > "$LAST"
    log "kinit ok (prev=$prev ticket_ok=$ticket_ok last=$last_date)"
    netbird login --extend
  else
    log "kinit failed (prev=$prev ticket_ok=$ticket_ok last=$last_date)"
    exit 1
  fi
fi
