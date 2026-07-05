#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE="iran-streaming"
ADDR_LIST="DST-IRAN-STREAMING-TO-OUTBOUND"
DB_FILE="$ROOT_DIR/services/$SERVICE/database/domains.txt"
DOMAINS_FILE="$ROOT_DIR/iran-streaming-domains.txt"
URLS_FILE="$ROOT_DIR/iran-streaming-urls.txt"
OUT_DIR="$ROOT_DIR/services/$SERVICE/output"
LIST_DOMAINS="$OUT_DIR/list-domains.rsc"
LIST_ALL="$OUT_DIR/list-all.rsc"
ROOT_COMPAT="$ROOT_DIR/mikrotik-iran-streaming-address-list.rsc"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

find_python() {
  if [[ -n "${IRAN_STREAMING_PYTHON:-}" && -x "$IRAN_STREAMING_PYTHON" ]]; then
    printf '%s\n' "$IRAN_STREAMING_PYTHON"
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  elif command -v python >/dev/null 2>&1; then
    command -v python
  elif command -v py >/dev/null 2>&1; then
    command -v py
  fi
}

normalize_domains() {
  tr '[:upper:]' '[:lower:]' |
    sed -E 's/#.*$//; s#^https?://##; s#/.*$##; s/:.*$//; s/^\*\.//; s/[[:space:]]//g' |
    sed '/^$/d' |
    sort -u
}

regex_escape_domain() {
  sed 's/\./\\./g'
}

mkdir -p "$OUT_DIR"

PYTHON_BIN="$(find_python || true)"
if [[ -n "$PYTHON_BIN" ]]; then
  if ! "$PYTHON_BIN" "$ROOT_DIR/scripts/discover-iran-streaming.py"; then
    echo "warning: Python discovery failed; using database domains only" >&2
    normalize_domains < "$DB_FILE" > "$DOMAINS_FILE"
    awk '{print "https://" $0 "/"}' "$DOMAINS_FILE" > "$URLS_FILE"
  fi
else
  echo "warning: Python was not found; using database domains only" >&2
  normalize_domains < "$DB_FILE" > "$DOMAINS_FILE"
  awk '{print "https://" $0 "/"}' "$DOMAINS_FILE" > "$URLS_FILE"
fi

# Keep database domains included even if public discovery sources fail or miss them.
cat "$DB_FILE" "$DOMAINS_FILE" | normalize_domains > "$TMP_DIR/domains"
mv "$TMP_DIR/domains" "$DOMAINS_FILE"

{
  echo '# managed-by=mohavise-iran-streaming-route-list'
  echo '# project=iran-streaming-route-list'
  echo '# service=iran-streaming'
  echo '# List: Iranian streaming domains'
  echo "# RouterOS address-list: $ADDR_LIST"
  echo '# Source: services/iran-streaming/database/domains.txt'
  echo '# do-not-edit-manually'
  echo
  echo '/ip dns static'
  echo "remove [find address-list=$ADDR_LIST comment~\"iran-streaming:\"]"
  while IFS= read -r domain; do
    [[ -z "$domain" ]] && continue
    escaped="$(printf '%s' "$domain" | regex_escape_domain)"
    echo ":do { add regexp=\"(^|.*\\.)${escaped}\\$\" type=FWD address-list=$ADDR_LIST comment=\"iran-streaming:$domain\" } on-error={}"
  done < "$DOMAINS_FILE"
} > "$LIST_DOMAINS"

cp "$LIST_DOMAINS" "$LIST_ALL"
cp "$LIST_DOMAINS" "$ROOT_COMPAT"

echo "domains: $(wc -l < "$DOMAINS_FILE")"
echo "output: $LIST_ALL"
