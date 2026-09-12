#!/usr/bin/env bash
# test-matrix-push.sh — prove the Matrix -> ntfy -> device push chain without a phone.
#
# Registers two throwaway accounts, gives one a pusher shaped exactly like the one
# Element X registers (data.url = the ntfy base URL, pushkey = a fresh UnifiedPush
# topic), subscribes to that topic, sends a message from the other account, and
# prints what the device would have received. Both accounts are deactivated on exit,
# including on failure.
#
# Requires: the invite token in /HOMELAB/services/tuwunel/.env
# Usage:    bash /HOMELAB/configs/scripts/test-matrix-push.sh
#
# Interpreting the result:
#   - the capture shows a Matrix push payload (notification{event_id,room_id,...})
#          -> the whole chain works; a real phone would have woken up
#   - "rejected" in ntfy's reply, or a 404 in Tuwunel's log
#          -> the push key is stale or the gateway path/base-url is wrong
#   - no Tuwunel log output at all
#          -> normal: it only logs pushes when they FAIL
#
# It leaves one empty test room behind (both members are deactivated); delete it
# from an admin client if you care.
set -uo pipefail
trap cleanup EXIT
HS="https://matrix.alimunee.com"
NTFY="https://notification.alimunee.com"
UA="curl/8.9.1"
J() { python3 -c "import json,sys;d=json.load(sys.stdin);print(d$1)" 2>/dev/null; }

TOKEN=$(grep -oE '^[A-Z_]*REGISTRATION_TOKEN=.*' /HOMELAB/services/tuwunel/.env | head -1 | cut -d= -f2-)
[ -n "$TOKEN" ] || { echo "FAIL: registration token not found in .env"; exit 1; }
echo "[1] registration token located (masked): ${TOKEN:0:4}..."

UP_TOPIC="up$(openssl rand -hex 6)"
PUSHKEY="$NTFY/$UP_TOPIC"
echo "[2] this run's simulated phone endpoint: $PUSHKEY"

SFX=$(openssl rand -hex 3)
T1="vtphone$SFX"; T2="vtsender$SFX"
reg() {
  local u=$1 s
  s=$(curl -sS -A "$UA" -X POST -H 'Content-Type: application/json' \
      -d "{\"username\":\"$u\",\"password\":\"Pw-$u-9271\",\"device_id\":\"DEV1\"}" \
      "$HS/_matrix/client/v3/register?kind=user" | J "['session']")
  curl -sS -A "$UA" -X POST -H 'Content-Type: application/json' \
    -d "{\"username\":\"$u\",\"password\":\"Pw-$u-9271\",\"device_id\":\"DEV1\",\"auth\":{\"type\":\"m.login.registration_token\",\"token\":\"$TOKEN\",\"session\":\"$s\"}}" \
    "$HS/_matrix/client/v3/register?kind=user"
}
R1=$(reg "$T1"); R2=$(reg "$T2")
TOK1=$(echo "$R1" | J "['access_token']"); TOK2=$(echo "$R2" | J "['access_token']")
if [ -z "$TOK1" ] || [ -z "$TOK2" ]; then echo "FAIL: registration refused: $R1 $R2"; exit 1; fi
echo "[3] registered $T1 and $T2 (throwaway); invite flow works"

curl -sS -A "$UA" -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $TOK1" \
  -d "{\"pushkey\":\"$PUSHKEY\",\"app_id\":\"im.vector.app\",\"app_display_name\":\"Element X\",\"device_display_name\":\"Android\",\"kind\":\"http\",\"lang\":\"en\",\"data\":{\"url\":\"$NTFY\",\"format\":\"event_id_only\"}}" \
  -w '\n[4] pusher set -> HTTP %{http_code}\n' "$HS/_matrix/client/v3/pushers/set"

curl -sS -A "$UA" -N -m 25 "$NTFY/$UP_TOPIC/json" > /tmp/chain-capture.json 2>/dev/null &
CAP=$!
sleep 2
ROOM=$(curl -sS -A "$UA" -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $TOK1" \
  -d "{\"name\":\"push test\",\"invite\":[\"@$T2:alimunee.com\"]}" "$HS/_matrix/client/v3/createRoom" | J "['room_id']")
curl -sS -A "$UA" -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $TOK2" \
  -d '{}' "$HS/_matrix/client/v3/rooms/$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$ROOM")/join" -o /dev/null
sleep 1
curl -sS -A "$UA" -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $TOK2" \
  -d '{"msgtype":"m.text","body":"push chain test"}' \
  "$HS/_matrix/client/v3/rooms/$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$ROOM")/send/m.room.message/$(date +%s)" -w '\n[5] message sent -> HTTP %{http_code}\n'
sleep 8
kill $CAP 2>/dev/null
echo "[6] what the phone's distributor would have received:"
python3 - "$UP_TOPIC" <<'PYEOF'
import json, sys
topic = sys.argv[1]
bodies = []
for line in open('/tmp/chain-capture.json'):
    line = line.strip()
    if not line:
        continue
    try:
        d = json.loads(line)
    except Exception:
        continue
    if d.get('event') == 'message':
        bodies.append(d.get('message', ''))
if not bodies:
    print("     FAIL: nothing arrived on the device topic")
    print("     -> check ntfy's base-url, and that the pusher's pushkey is on that host")
    raise SystemExit(1)
for b in bodies:
    print("    ", b[:220])
print(f"     PASS: {len(bodies)} push payload(s) published to the device topic")
PYEOF
echo "[7] server-side view:"
echo "    Tuwunel push failures in the last 5 minutes (no output = none, which is normal):"
docker logs tuwunel --since 5m 2>&1 | grep -iE 'push gateway|push transaction' | tail -4
echo "    ntfy's own record of that device topic:"
sqlite3 -readonly /storage/data/ntfy/cache/cache.db \
  "select topic, count(*) as msgs, datetime(max(time),'unixepoch','localtime') as last from messages where topic='$UP_TOPIC' group by topic;"
cleanup() {
  [ -z "${TOK1:-}" ] && return 0
  for t in "$TOK1" "$TOK2"; do
  u=$([ "$t" = "$TOK1" ] && echo "$T1" || echo "$T2")
  curl -sS -A "$UA" -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $t" \
    -d "{\"auth\":{\"type\":\"m.login.password\",\"identifier\":{\"type\":\"m.id.user\",\"user\":\"$u\"},\"password\":\"Pw-$u-9271\"}}" \
    "$HS/_matrix/client/v3/account/deactivate" -o /dev/null
done
  echo "[8] both throwaway accounts deactivated"
}
