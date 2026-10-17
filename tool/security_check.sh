#!/usr/bin/env bash
# Direct-API security checks for Findly's row level security and Storage
# policies. Talks to Supabase over HTTPS exactly as a malicious client could,
# bypassing the Flutter UI entirely.
#
# Requirements: curl, jq, python3, and two confirmed test accounts in a
# DEVELOPMENT project (never production). The URL and publishable key are
# read from env/dev.json; passwords are read from the environment or
# prompted for, and are never written to disk or printed.
#
#   FINDLY_USER_A_EMAIL=a@example.com FINDLY_USER_B_EMAIL=b@example.com \
#     tool/security_check.sh
#
# The script cleans up the rows and objects it creates.

set -euo pipefail

CONFIG=${CONFIG:-env/dev.json}
URL=$(jq -r .SUPABASE_URL "$CONFIG")
KEY=$(jq -r .SUPABASE_PUBLISHABLE_KEY "$CONFIG")
BUCKET=report-photos

: "${FINDLY_USER_A_EMAIL:?Set FINDLY_USER_A_EMAIL}"
: "${FINDLY_USER_B_EMAIL:?Set FINDLY_USER_B_EMAIL}"
if [[ -z ${FINDLY_USER_A_PASSWORD:-} ]]; then
  read -rsp "Password for user A: " FINDLY_USER_A_PASSWORD; echo
fi
if [[ -z ${FINDLY_USER_B_PASSWORD:-} ]]; then
  read -rsp "Password for user B: " FINDLY_USER_B_PASSWORD; echo
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
PASSED=0
FAILED=0

pass() { echo "PASS  $1"; PASSED=$((PASSED + 1)); }
fail() { echo "FAIL  $1"; FAILED=$((FAILED + 1)); }
expect() { # expect NAME CONDITION_RESULT(yes/no) DETAIL
  if [[ $2 == yes ]]; then pass "$1"; else fail "$1 ($3)"; fi
}
is_2xx() { [[ $1 =~ ^2 ]] && echo yes || echo no; }
not_2xx() { [[ $1 =~ ^2 ]] && echo no || echo yes; }

# api METHOD PATH TOKEN [JSON] -> prints HTTP status; body in $TMP/body
api() {
  local method=$1 path=$2 token=$3 data=${4:-}
  local args=(-s -o "$TMP/body" -w '%{http_code}' -X "$method" "$URL$path"
    -H "apikey: $KEY" -H 'Content-Type: application/json'
    -H 'Prefer: return=representation')
  [[ -n $token ]] && args+=(-H "Authorization: Bearer $token")
  [[ -n $data ]] && args+=(--data "$data")
  curl "${args[@]}"
}

# upload TOKEN OBJECT_PATH FILE CONTENT_TYPE [extra curl args...]
upload() {
  local token=$1 path=$2 file=$3 type=$4
  shift 4
  curl -s -o "$TMP/body" -w '%{http_code}' -X POST \
    "$URL/storage/v1/object/$BUCKET/$path" \
    -H "apikey: $KEY" -H "Authorization: Bearer $token" \
    -H "Content-Type: $type" --data-binary "@$file" "$@"
}

download() { # download TOKEN OBJECT_PATH
  curl -s -o "$TMP/body" -w '%{http_code}' \
    "$URL/storage/v1/object/authenticated/$BUCKET/$2" \
    -H "apikey: $KEY" -H "Authorization: Bearer $1"
}

remove_objects() { # remove_objects TOKEN PATH...
  local token=$1
  shift
  local prefixes
  prefixes=$(printf '%s\n' "$@" | jq -R . | jq -sc '{prefixes: .}')
  curl -s -o "$TMP/body" -w '%{http_code}' -X DELETE \
    "$URL/storage/v1/object/$BUCKET" \
    -H "apikey: $KEY" -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' --data "$prefixes"
}

sign_in() { # sign_in EMAIL PASSWORD -> "token user_id"
  local body
  body=$(jq -nc --arg e "$1" --arg p "$2" '{email: $e, password: $p}')
  curl -s "$URL/auth/v1/token?grant_type=password" \
    -H "apikey: $KEY" -H 'Content-Type: application/json' --data "$body" |
    jq -r '[.access_token // "", .user.id // ""] | join(" ")'
}

photo_name() { # photo_name USER_ID EXT
  printf '%s/%s-%s.%s' "$1" "$(python3 -c 'import time; print(int(time.time()*1000))')" \
    "$(openssl rand -hex 4)" "$2"
}

read -r A_TOKEN A_ID <<<"$(sign_in "$FINDLY_USER_A_EMAIL" "$FINDLY_USER_A_PASSWORD")"
read -r B_TOKEN B_ID <<<"$(sign_in "$FINDLY_USER_B_EMAIL" "$FINDLY_USER_B_PASSWORD")"
if [[ -z ${A_TOKEN:-} || -z ${B_TOKEN:-} ]]; then
  echo "Could not sign in both test users (check emails, passwords, confirmation)." >&2
  exit 1
fi
unset FINDLY_USER_A_PASSWORD FINDLY_USER_B_PASSWORD

TODAY=$(date -u +%Y-%m-%d)
FUTURE=$(python3 -c 'import datetime; print(datetime.date.today() + datetime.timedelta(days=10))')
report_json() { # report_json TITLE [EXTRA_JQ]
  jq -nc --arg t "$1" --arg d "$TODAY" \
    "{type: \"lost\", title: \$t, description: \"Created by security_check.sh\",
      category: \"other\", location: \"Security test lab\", event_date: \$d} ${2:-}"
}

# Test files: a valid 1x1 PNG, a text file, and a 6 MB file.
python3 - "$TMP" <<'PY'
import base64, sys, os
d = sys.argv[1]
png = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")
open(os.path.join(d, "ok.png"), "wb").write(png)
open(os.path.join(d, "note.txt"), "w").write("not an image")
open(os.path.join(d, "big.png"), "wb").write(png + os.urandom(6 * 1024 * 1024))
PY

echo "== Reports table (RLS + column privileges)"

status=$(api GET '/rest/v1/reports?select=id&limit=1' '')
expect "anonymous request cannot read reports" \
  "$([[ ! $status =~ ^2 || $(cat "$TMP/body") == '[]' ]] && echo yes || echo no)" "HTTP $status"

status=$(api GET '/rest/v1/reports?select=id&limit=1' 'not-a-valid-jwt')
expect "invalid/tampered token is rejected" "$(not_2xx "$status")" "HTTP $status"

status=$(api POST /rest/v1/reports "$A_TOKEN" "$(report_json 'Security test item')")
A_REPORT=$(jq -r '.[0].id // empty' "$TMP/body")
OWNER=$(jq -r '.[0].owner_id // empty' "$TMP/body")
expect "A can create a report" "$(is_2xx "$status")" "HTTP $status"
expect "owner_id is set by the server to A" "$([[ $OWNER == "$A_ID" ]] && echo yes || echo no)" "got '$OWNER'"

status=$(api GET "/rest/v1/reports?id=eq.$A_REPORT&select=id" "$B_TOKEN")
expect "B can read A's report (reports are visible to signed-in users)" \
  "$([[ $status == 200 && $(jq length "$TMP/body") == 1 ]] && echo yes || echo no)" "HTTP $status"

status=$(api PATCH "/rest/v1/reports?id=eq.$A_REPORT" "$B_TOKEN" '{"title":"Changed by B"}')
expect "B cannot update A's report" \
  "$([[ ! $status =~ ^2 || $(jq length "$TMP/body") == 0 ]] && echo yes || echo no)" "HTTP $status"

status=$(api DELETE "/rest/v1/reports?id=eq.$A_REPORT" "$B_TOKEN")
expect "B cannot delete A's report" \
  "$([[ ! $status =~ ^2 || $(jq length "$TMP/body") == 0 ]] && echo yes || echo no)" "HTTP $status"

api GET "/rest/v1/reports?id=eq.$A_REPORT&select=title" "$A_TOKEN" >/dev/null
expect "A's report is unchanged after B's attempts" \
  "$([[ $(jq -r '.[0].title' "$TMP/body") == 'Security test item' ]] && echo yes || echo no)" \
  "title now '$(jq -r '.[0].title' "$TMP/body")'"

status=$(api POST /rest/v1/reports "$B_TOKEN" "$(report_json 'Forged owner' "+ {owner_id: \"$A_ID\"}")")
expect "B cannot create a report owned by A" "$(not_2xx "$status")" "HTTP $status"

status=$(api PATCH "/rest/v1/reports?id=eq.$A_REPORT" "$A_TOKEN" "{\"owner_id\":\"$B_ID\"}")
expect "owner_id cannot be changed" "$(not_2xx "$status")" "HTTP $status"

status=$(api POST /rest/v1/reports "$A_TOKEN" "$(report_json 'Fake demo' '+ {is_demo: true}')")
expect "clients cannot set is_demo" "$(not_2xx "$status")" "HTTP $status"

status=$(api PATCH "/rest/v1/reports?id=eq.$A_REPORT" "$A_TOKEN" '{"created_at":"2001-01-01T00:00:00Z"}')
expect "created_at cannot be changed" "$(not_2xx "$status")" "HTTP $status"

status=$(api PATCH "/rest/v1/reports?id=eq.$A_REPORT" "$A_TOKEN" '{"type":"found"}')
expect "report type cannot be changed after creation" "$(not_2xx "$status")" "HTTP $status"

status=$(api POST /rest/v1/reports "$A_TOKEN" "$(report_json 'ab')")
expect "too-short title is rejected by the database" "$(not_2xx "$status")" "HTTP $status"

status=$(api POST /rest/v1/reports "$A_TOKEN" "$(report_json 'Future item' "+ {event_date: \"$FUTURE\"}")")
expect "future event_date is rejected by the database" "$(not_2xx "$status")" "HTTP $status"

echo "== Storage (report-photos bucket)"

A_PHOTO=$(photo_name "$A_ID" png)
status=$(upload "$A_TOKEN" "$A_PHOTO" "$TMP/ok.png" image/png)
expect "A can upload a PNG to their own folder" "$(is_2xx "$status")" "HTTP $status"

status=$(upload "$B_TOKEN" "$(photo_name "$A_ID" png)" "$TMP/ok.png" image/png)
expect "B cannot upload into A's folder" "$(not_2xx "$status")" "HTTP $status"

status=$(upload "$A_TOKEN" "$A_PHOTO" "$TMP/ok.png" image/png -H 'x-upsert: true')
expect "A cannot overwrite an existing object" "$(not_2xx "$status")" "HTTP $status"

status=$(upload "$A_TOKEN" "$A_ID/nested/$(basename "$(photo_name "$A_ID" png)")" "$TMP/ok.png" image/png)
expect "uploads into nested folders are rejected" "$(not_2xx "$status")" "HTTP $status"

status=$(upload "$A_TOKEN" "$(photo_name "$A_ID" png)" "$TMP/note.txt" text/plain)
expect "non-image content type is rejected" "$(not_2xx "$status")" "HTTP $status"

status=$(upload "$A_TOKEN" "$(photo_name "$A_ID" png)" "$TMP/big.png" image/png)
expect "files over 5 MB are rejected" "$(not_2xx "$status")" "HTTP $status"

status=$(download "$B_TOKEN" "$A_PHOTO")
expect "B cannot read A's photo before it is attached to a report" "$(not_2xx "$status")" "HTTP $status"

status=$(api PATCH "/rest/v1/reports?id=eq.$A_REPORT" "$A_TOKEN" "{\"photo_path\":\"$A_PHOTO\"}")
expect "A can attach their photo to their report" "$(is_2xx "$status")" "HTTP $status"

status=$(download "$B_TOKEN" "$A_PHOTO")
expect "B can view A's photo once it is attached to a report" "$(is_2xx "$status")" "HTTP $status"

remove_objects "$B_TOKEN" "$A_PHOTO" >/dev/null
status=$(download "$A_TOKEN" "$A_PHOTO")
expect "B cannot delete A's photo" "$(is_2xx "$status")" "photo gone, HTTP $status"

B_PHOTO=$(photo_name "$B_ID" png)
upload "$B_TOKEN" "$B_PHOTO" "$TMP/ok.png" image/png >/dev/null
status=$(api PATCH "/rest/v1/reports?id=eq.$A_REPORT" "$A_TOKEN" "{\"photo_path\":\"$B_PHOTO\"}")
expect "A cannot point their report at B's photo" "$(not_2xx "$status")" "HTTP $status"

status=$(api PATCH "/rest/v1/reports?id=eq.$A_REPORT" "$A_TOKEN" '{"status":"resolved"}')
expect "A can resolve their own report and resolved_at is set" \
  "$([[ $status == 200 && $(jq -r '.[0].resolved_at' "$TMP/body") != null ]] && echo yes || echo no)" "HTTP $status"

echo "== Cleanup"
api DELETE "/rest/v1/reports?id=eq.$A_REPORT" "$A_TOKEN" >/dev/null
remove_objects "$A_TOKEN" "$A_PHOTO" >/dev/null
remove_objects "$B_TOKEN" "$B_PHOTO" >/dev/null
echo "Removed test report and photos."

echo
echo "$PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]]
