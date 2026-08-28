#!/usr/bin/env bash
# Seeds a simulator with a real photo library so the delete path can be tested.
#
# Prune's whole job is deleting photos, and that path went untested for months
# because the simulator starts with an empty library and EndToEndTests used to
# XCTSkip itself into a green run. This makes a real run reproducible.
#
# Usage: tools/seed_simulator_photos.sh [device-udid] [count]
set -euo pipefail

DEVICE="${1:-booted}"
COUNT="${2:-12}"
BUNDLE_ID="com.isotropic.prune"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 - "$TMP" "$COUNT" <<'PY'
import zlib, struct, sys, os
out, count = sys.argv[1], int(sys.argv[2])
def png(path, r, g, b, w=400, h=400):
    raw = b''.join(b'\x00' + bytes([r, g, b] * w) for _ in range(h))
    def chunk(t, d):
        c = t + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    hdr = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', hdr)
        + chunk(b'IDAT', zlib.compress(raw, 6)) + chunk(b'IEND', b''))
for i in range(count):
    png(os.path.join(out, f"seed{i:02d}.png"), (i*20) % 256, (i*37) % 256, (i*67) % 256)
print(f"generated {count} images")
PY

xcrun simctl bootstatus "$DEVICE" -b >/dev/null 2>&1 || xcrun simctl boot "$DEVICE" || true
xcrun simctl addmedia "$DEVICE" "$TMP"/*.png
xcrun simctl privacy "$DEVICE" grant photos "$BUNDLE_ID"

echo "Seeded $COUNT photos and granted photo access to $BUNDLE_ID on $DEVICE."
echo
echo "Run the delete test:"
echo "  xcodebuild test -project Prune/Prune.xcodeproj -scheme Prune \\"
echo "    -destination 'platform=iOS Simulator,id=<udid>' \\"
echo "    -only-testing:PruneUITests/EndToEndTests"
echo
echo "Verify assets really moved to Recently Deleted (read LIVE db — it is WAL-mode,"
echo "so copying just the .sqlite file shows stale results):"
echo "  DB=~/Library/Developer/CoreSimulator/Devices/<udid>/data/Media/PhotoData/Photos.sqlite"
echo "  sqlite3 \"file:\$DB?mode=ro\" 'SELECT ZTRASHEDSTATE, count(*) FROM ZASSET GROUP BY 1;'"
echo "  # ZTRASHEDSTATE 0 = live, 1 = Recently Deleted"
