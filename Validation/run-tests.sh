#!/bin/bash
set -euo pipefail

validation_root="$(cd "$(dirname "$0")/.." && pwd)"
validation_output="${1:-$(mktemp -d "${TMPDIR:-/tmp/}PhotoBrowser-Validation.XXXXXX")}"
mkdir -p "$validation_output"
validation_output="$(cd "$validation_output" && pwd)"
if [[ -e "$validation_output/Results.xcresult" ]]; then
    echo "Use a new output directory; Results.xcresult already exists." >&2
    exit 2
fi

validation_device="${SIMULATOR_UDID:-}"
if [[ -z "$validation_device" ]]; then
    validation_device="$(xcrun simctl list devices available --json | python3 -c '
import json, sys
items = [d for runtime, devices in json.load(sys.stdin)["devices"].items() if ".iOS-" in runtime for d in devices if "iPhone" in d["name"]]
items.sort(key=lambda d: d["state"] != "Booted")
if not items: sys.exit("No available iPhone simulator")
print(items[0]["udid"])
')"
fi
validation_state="$(xcrun simctl list devices --json | python3 -c '
import json, sys
print(next(d["state"] for devices in json.load(sys.stdin)["devices"].values() for d in devices if d["udid"] == sys.argv[1]))
' "$validation_device")"
if [[ "$validation_state" != "Booted" ]]; then xcrun simctl boot "$validation_device"; fi
xcrun simctl bootstatus "$validation_device" -b

ruby "$validation_root/Validation/Rotation/generate_project.rb" "$validation_output"
validation_args=(-project "$validation_output/Rotation.xcodeproj" -scheme Rotation
    -destination "platform=iOS Simulator,id=$validation_device"
    -derivedDataPath "$validation_output/DerivedData" CODE_SIGNING_ALLOWED=NO)
xcodebuild "${validation_args[@]}" build-for-testing > "$validation_output/build.log" 2>&1 || {
    validation_status=$?
    tail -80 "$validation_output/build.log"
    exit "$validation_status"
}
# Set Photos permission before starting XCTest; changing TCC while it runs can terminate the host.
xcrun simctl install "$validation_device" "$validation_output/DerivedData/Build/Products/Debug-iphonesimulator/RotationHost.app"
xcrun simctl privacy "$validation_device" grant photos-add com.jxphotobrowser.RotationHost

validation_selection=(-only-testing:RotationTests -only-testing:RotationUITests)
case "${TEST_SUITE:-all}" in
    state) validation_selection=(-only-testing:RotationTests) ;;
    ui) validation_selection=(-only-testing:RotationUITests) ;;
    all) ;;
    *) echo "TEST_SUITE must be state, ui, or all" >&2; exit 2 ;;
esac
xcodebuild "${validation_args[@]}" -parallel-testing-enabled NO -collect-test-diagnostics never \
    -resultBundlePath "$validation_output/Results.xcresult" "${validation_selection[@]}" \
    test-without-building > "$validation_output/test.log" 2>&1 || {
    validation_status=$?
    tail -80 "$validation_output/test.log"
    exit "$validation_status"
}
xcrun xcresulttool get test-results summary --path "$validation_output/Results.xcresult" --format json
