#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE="iran-streaming"
ADDR_LIST="DST-IRAN-STREAMING-TO-OUTBOUND"
DB_FILE="$ROOT_DIR/services/$SERVICE/database/domains.txt"
DOMAINS_FILE="$ROOT_DIR/iran-streaming-domains.txt"
URLS_FILE="$ROOT_DIR/iran-streaming-urls.txt"
OUT_DIR="$ROOT_DIR/services/$SERVICE/output"
LIST_ALL="$OUT_DIR/list-all.rsc"
MIN_DOMAIN_COUNT="${MIN_DOMAIN_COUNT:-20}"
MAX_DROP_PERCENT="${MAX_DROP_PERCENT:-20}"
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
    awk '
        function valid(domain, labels, n, i, label, tld) {
            if (domain == "" || length(domain) > 253) return 0
            if (domain ~ /[[:space:]]/ || domain ~ /\.\./) return 0
            if (domain ~ /^\./ || domain ~ /\.$/) return 0
            if (domain ~ /^[0-9]+(\.[0-9]+){3}$/) return 0
            if (domain !~ /^[a-z0-9.-]+$/) return 0
            n = split(domain, labels, ".")
            if (n < 2) return 0
            for (i = 1; i <= n; i++) {
                label = labels[i]
                if (label == "" || length(label) > 63) return 0
                if (label ~ /^-/ || label ~ /-$/) return 0
                if (label !~ /^[a-z0-9-]+$/) return 0
            }
            tld = labels[n]
            return length(tld) >= 2 && length(tld) <= 63 && tld ~ /^[a-z]+$/
        }
        {
            line = tolower($0)
            gsub(/\r/, "", line)
            sub(/#.*/, "", line)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
            sub(/^https?:\/\//, "", line)
            sub(/\/.*/, "", line)
            sub(/:[0-9]+$/, "", line)
            sub(/^\*\./, "", line)
            sub(/\.$/, "", line)
            if (valid(line)) print line
        }
    ' | LC_ALL=C sort -u
}

validate_domain_file() {
    local file="$1"
    local label="$2"
    local normalized="$TMP_DIR/${label}.validated"

    normalize_domains < "$file" > "$normalized"
    if ! cmp -s "$file" "$normalized"; then
        echo "$label contains invalid, duplicate, unsorted, or non-canonical domain entries" >&2
        diff -u "$file" "$normalized" | head -100 >&2 || true
        exit 1
    fi
}

validate_count() {
    local file="$1"
    local count
    count="$(wc -l < "$file" | tr -d ' ')"
    if (( count < MIN_DOMAIN_COUNT )); then
        echo "Domain count $count is below minimum $MIN_DOMAIN_COUNT" >&2
        exit 1
    fi
    printf '%s\n' "$count"
}

validate_drop() {
    local new_file="$1"
    local old_file="$2"
    [[ -f "$old_file" ]] || return 0

    local new_count old_count minimum_allowed
    new_count="$(wc -l < "$new_file" | tr -d ' ')"
    old_count="$(grep -Ec '^[a-z0-9]' "$old_file" || true)"
    (( old_count > 0 )) || return 0

    minimum_allowed=$((old_count * (100 - MAX_DROP_PERCENT) / 100))
    if (( new_count < minimum_allowed )); then
        echo "Refusing sudden domain-count drop from $old_count to $new_count (limit: ${MAX_DROP_PERCENT}%)" >&2
        exit 1
    fi
}

regex_escape_domain() {
    sed 's/\./\\./g'
}

[[ -f "$DB_FILE" ]] || { echo "Missing database: $DB_FILE" >&2; exit 1; }
mkdir -p "$OUT_DIR"

normalize_domains < "$DB_FILE" > "$TMP_DIR/database-domains.txt"
validate_count "$TMP_DIR/database-domains.txt" >/dev/null

PYTHON_BIN="$(find_python || true)"
if [[ -n "$PYTHON_BIN" ]]; then
    if ! "$PYTHON_BIN" "$ROOT_DIR/scripts/discover-iran-streaming.py"; then
        echo "warning: Python discovery failed; using database domains only" >&2
        cp "$TMP_DIR/database-domains.txt" "$TMP_DIR/discovered-domains.txt"
    else
        normalize_domains < "$DOMAINS_FILE" > "$TMP_DIR/discovered-domains.txt"
    fi
else
    echo "warning: Python was not found; using database domains only" >&2
    cp "$TMP_DIR/database-domains.txt" "$TMP_DIR/discovered-domains.txt"
fi

cat "$TMP_DIR/database-domains.txt" "$TMP_DIR/discovered-domains.txt" | normalize_domains > "$TMP_DIR/final-domains.txt"
validate_domain_file "$TMP_DIR/final-domains.txt" "final-domains"
validate_drop "$TMP_DIR/final-domains.txt" "$DOMAINS_FILE"
domain_count="$(validate_count "$TMP_DIR/final-domains.txt")"

cp "$TMP_DIR/final-domains.txt" "$DOMAINS_FILE"
awk '{ print "https://" $0 "/" }' "$DOMAINS_FILE" > "$URLS_FILE"

{
    echo '# managed-by=mohavise-mikrotik-iran-streaming-route-list'
    echo '# project=mikrotik-iran-streaming-route-list'
    echo '# service=iran-streaming'
    echo '# do-not-edit-manually'
    echo
    echo '/ip dns static'
    echo "remove [find address-list=$ADDR_LIST comment~\"iran-streaming:\"]"
    while IFS= read -r domain; do
        escaped="$(printf '%s' "$domain" | regex_escape_domain)"
        printf ':do { add regexp="(^|.*\\.)%s\\$" type=FWD address-list=%s comment="iran-streaming:%s" } on-error={}\n' \
            "$escaped" "$ADDR_LIST" "$domain"
    done < "$DOMAINS_FILE"
} > "$LIST_ALL"

generated_count="$(grep -c 'comment="iran-streaming:' "$LIST_ALL")"
if (( generated_count != domain_count )); then
    echo "Generated RouterOS entry count $generated_count does not match domain count $domain_count" >&2
    exit 1
fi

echo "Generated $domain_count validated streaming domains."
echo "Output: $LIST_ALL"
