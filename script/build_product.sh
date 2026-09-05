#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swift-cache"
swift build -c "${CONFIG:-debug}" --disable-sandbox
BIN=$(swift build -c "${CONFIG:-debug}" --show-bin-path)
APP="${PRODUCT_APP_PATH:-$PWD/dist/Usage Capacity.app}"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks" "$APP/Contents/Helpers"
cp "$BIN/OpenUsage" "$APP/Contents/MacOS/UsageCapacity"
cp "$BIN/openusage-cli" "$APP/Contents/Helpers/aiusage"
for name in OpenUsage_OpenUsage KeyboardShortcuts_KeyboardShortcuts; do cp -R "$BIN/$name.bundle" "$APP/Contents/Resources/"; done
cp -R "$BIN/Sparkle.framework" "$APP/Contents/Frameworks/"
cp -R Notices "$APP/Contents/Resources/"
# The upstream logo is not part of this fork's product identity.
find "$APP/Contents/Resources" -name 'openusage.svg' -delete
install_name_tool -add_rpath '@executable_path/../Frameworks' "$APP/Contents/MacOS/UsageCapacity"
install_name_tool -add_rpath '@executable_path/../Frameworks' "$APP/Contents/Helpers/aiusage" 2>/dev/null || true
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleExecutable</key><string>UsageCapacity</string><key>CFBundleIdentifier</key><string>com.ainatechnologies.usagecapacity</string><key>CFBundleName</key><string>Usage Capacity</string><key>CFBundleDisplayName</key><string>Usage Capacity</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>0.7.0</string><key>CFBundleShortVersionString</key><string>0.7.0</string><key>LSUIElement</key><true/><key>LSMinimumSystemVersion</key><string>15.0</string><key>NSPrincipalClass</key><string>NSApplication</string></dict></plist>
PLIST
chmod -R u+w "$APP"
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
echo "$APP"
