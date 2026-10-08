#!/bin/bash
# Installs the built app on iOS simulators, plays the scripted demo round
# (`-pantryDemo`, see Sources/PantryUI/PantryRootView.swift) and saves screenshots.
# Fails if the app dies, with or without the demo.
#
# usage: scripts/ci-screenshots.sh <path to Pantry.app> <output directory>
set -euo pipefail

APP="$1"
OUT="$2"
BUNDLE_ID="ai.skasiehi.pantry"
mkdir -p "$OUT"
FAILED=0

# Newest available simulator with exactly this name; prints its UDID or nothing.
find_device() {
  xcrun simctl list devices available -j | python3 -c '
import json, re, sys
wanted = sys.argv[1]
best = None
for runtime, devices in json.load(sys.stdin)["devices"].items():
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not match:
        continue
    version = (int(match.group(1)), int(match.group(2)))
    for device in devices:
        if device["name"] == wanted and (best is None or version > best[0]):
            best = (version, device["udid"])
print(best[1] if best else "")
' "$1"
}

shot() {
  xcrun simctl io "$1" screenshot "$OUT/$2.png" > /dev/null 2>&1
  sips -Z 1400 "$OUT/$2.png" > /dev/null 2>&1 || true
}

# Launches with the given arguments and prints the app's process id.
launch() {
  local udid="$1"
  shift
  xcrun simctl terminate "$udid" "$BUNDLE_ID" > /dev/null 2>&1 || true
  xcrun simctl launch "$udid" "$BUNDLE_ID" "$@" | awk '{print $NF}'
}

must_be_alive() {
  if ! kill -0 "$1" 2> /dev/null; then
    echo "::error::The app died on $2 ($3)."
    echo "dead: $2 $3" >> "$OUT/status.txt"
    return 1
  fi
  echo "alive: $2 $3" >> "$OUT/status.txt"
}

run_on() {
  local name="$1" label="$2" udid pid
  udid="$(find_device "$name")"
  if [ -z "$udid" ]; then
    echo "skipped: no simulator named $name" | tee -a "$OUT/status.txt"
    return 0
  fi
  echo "== $name ($udid)"
  xcrun simctl boot "$udid" 2> /dev/null || true
  xcrun simctl bootstatus "$udid" -b > /dev/null
  xcrun simctl install "$udid" "$APP"

  # A cold start with the sound on: the empty Pantry round, and proof the audio path doesn't crash.
  pid="$(launch "$udid")"
  sleep 8
  shot "$udid" "$label-1-empty"
  must_be_alive "$pid" "$name" "plain launch" || FAILED=1

  # The scripted round, caught mid-flight a few times and then settled.
  pid="$(launch "$udid" -pantryDemo)"
  sleep 2.5
  shot "$udid" "$label-2-adding-a"
  sleep 0.6
  shot "$udid" "$label-2-adding-b"
  sleep 0.6
  shot "$udid" "$label-2-adding-c"
  sleep 7
  shot "$udid" "$label-3-round"
  must_be_alive "$pid" "$name" "demo round" || FAILED=1

  pid="$(launch "$udid" -pantryDemo -pantryDemoServe)"
  sleep 11
  shot "$udid" "$label-4-score"
  must_be_alive "$pid" "$name" "demo round, served" || FAILED=1

  # Pantry mode: a few picks, then the verdict.
  pid="$(launch "$udid" -pantryDemoPantry)"
  sleep 7
  shot "$udid" "$label-5-pantry"
  must_be_alive "$pid" "$name" "pantry round" || FAILED=1

  pid="$(launch "$udid" -pantryDemoPantry -pantryDemoServe)"
  sleep 9
  shot "$udid" "$label-6-pantry-verdict"
  must_be_alive "$pid" "$name" "pantry round, served" || FAILED=1

  # Kitchen mode before a vessel is chosen: the bare burner and the two choices.
  pid="$(launch "$udid" -pantryMuted -pantryMode kitchen)"
  sleep 6
  shot "$udid" "$label-7-kitchen-bare"
  must_be_alive "$pid" "$name" "kitchen, bare burner" || FAILED=1

  xcrun simctl shutdown "$udid" || true
}

xcrun simctl list devices available > "$OUT/simulators.txt" || true
run_on "iPhone 16" "iphone16"
run_on "iPhone SE (3rd generation)" "iphonese"
cat "$OUT/status.txt"
exit "$FAILED"
