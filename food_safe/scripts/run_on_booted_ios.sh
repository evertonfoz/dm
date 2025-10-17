#!/usr/bin/env bash
set -euo pipefail

# Finds the currently booted iOS Simulator UDID and runs `flutter run -d <UDID>`.
# This script is intentionally simple and uses Python to parse the JSON output
# from `xcrun simctl list devices --json` to avoid relying on external tools
# like `jq`.

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

DRY_RUN=${DRY_RUN:-0}

# Try to get simctl JSON output; tolerate failures
SIM_JSON=$(xcrun simctl list devices --json 2>/dev/null || true)
UDID=""

if [ -n "$SIM_JSON" ]; then
    # Use python to parse JSON: find booted or list all iOS simulators
    UDID=$(printf '%s' "$SIM_JSON" | python3 - <<'PY' 2>/dev/null || true
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
booted = []
ios_devices = []
for runtime, devices in data.get("devices", {}).items():
    is_ios = 'iOS' in runtime
    if not is_ios:
        continue
    for d in devices:
        name = d.get('name')
        udid = d.get('udid')
        state = d.get('state')
        ios_devices.append((name, runtime, udid, state))
        if state == 'Booted':
            booted.append(udid)
if booted:
    print(f"BOOTED:{booted[0]}", file=sys.stderr)
    print(booted[0])
    sys.exit(0)
# No booted, list all and select first
for name, runtime, udid, state in ios_devices:
    print(f"- {name} ({runtime}) - {udid} [{state}]", file=sys.stderr)
if ios_devices:
    print('', file=sys.stderr)
    print(f"SELECTED:{ios_devices[0][2]}", file=sys.stderr)
    print(ios_devices[0][2])
sys.exit(0)
PY
)
fi

# Fallback to text parsing if SIM_JSON is empty or parsing failed
if [ -z "${UDID:-}" ]; then
    # Check for booted via text
    BOOTED_UDID=$(xcrun simctl list devices 2>/dev/null | grep 'Booted' | sed -E 's/.*\(([0-9A-Fa-f-]+)\).*/\1/' | head -n1 || true)
    if [ -n "$BOOTED_UDID" ]; then
        UDID=$BOOTED_UDID
    else
        # List available iOS simulators via text
        echo "No simulators are currently Booted. Available iOS simulators:"
        DEVICES_TEXT=$(xcrun simctl list devices 2>/dev/null || true)
        if echo "$DEVICES_TEXT" | grep -q 'iPhone\|iPad'; then
            echo "$DEVICES_TEXT" | grep -E '(iPhone|iPad)' | head -10  # Limit to first 10 for readability
            echo ''
        fi
        # Select first UDID from text (UDID is 36 hex chars)
        FIRST_UDID=$(echo "$DEVICES_TEXT" | sed -n 's/.*(\([0-9A-Fa-f-]\{36\}\)).*/\1/p' | head -n1 || true)
        if [ -n "$FIRST_UDID" ]; then
            echo "Selecting first available simulator UDID: $FIRST_UDID"
            UDID=$FIRST_UDID
        fi
    fi
fi

if [ -z "${UDID:-}" ]; then
    echo "No iOS simulators found. Running flutter without explicit device (default)."
    cd "$WORKSPACE_ROOT"
    if [ "$DRY_RUN" = "1" ]; then
        echo "DRY_RUN=1 set; skipping flutter run. Would run: flutter run"
        exit 0
    fi
    exec flutter run
fi

echo "Selected iOS simulator UDID: $UDID"

# Check whether it's booted; if not, boot it and wait
is_booted=$(xcrun simctl list devices --json | python3 -c "import sys, json
data=json.load(sys.stdin)
for runtime, devices in data.get('devices',{}).items():
    for d in devices:
        if d.get('udid') == '$UDID':
            print(d.get('state'))
            sys.exit(0)
print('Shutdown')
")

if [ "$is_booted" != "Booted" ]; then
    echo "Booting simulator $UDID..."
    # Boot the device; xcrun simctl boot will succeed if already booted too
    xcrun simctl boot "$UDID" || true

    # Wait until simctl reports it as Booted (timeout after ~60s)
    attempts=0
    until [ "$attempts" -ge 30 ]; do
        state=$(xcrun simctl list devices --json | python3 -c "import sys, json
data=json.load(sys.stdin)
for runtime, devices in data.get('devices',{}).items():
    for d in devices:
        if d.get('udid') == '$UDID':
            print(d.get('state'))
            sys.exit(0)
print('Shutdown')
")
        if [ "$state" = "Booted" ]; then
            echo "Simulator $UDID is Booted."
            break
        fi
        attempts=$((attempts+1))
        sleep 2
    done
    if [ "$state" != "Booted" ]; then
        echo "Timed out waiting for simulator to boot (UDID: $UDID)." >&2
        exit 3
    fi
else
    echo "Simulator $UDID already booted."
fi

# Run flutter on the detected simulator (unless DRY_RUN)
cd "$WORKSPACE_ROOT"
if [ "$DRY_RUN" = "1" ]; then
    echo "DRY_RUN=1 set; skipping flutter run. Would run: flutter run -d $UDID"
    exit 0
fi

exec flutter run -d "$UDID"
