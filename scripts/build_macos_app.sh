#!/usr/bin/env bash
set -euo pipefail

root_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
dist_dir="$root_dir/dist"
app_name="Long Paste Fix"
app_dir="$dist_dir/$app_name.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"

if [ -d "$app_dir" ]; then
  rm -R "$app_dir"
fi

mkdir -p "$macos_dir" "$resources_dir" "$dist_dir"

if [ ! -f "$root_dir/assets/AppIcon.icns" ]; then
  "$root_dir/scripts/generate_app_icon.swift"
  iconutil -c icns "$root_dir/assets/AppIcon.iconset" -o "$root_dir/assets/AppIcon.icns"
fi

cat > "$contents_dir/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>Long Paste Fix</string>
  <key>CFBundleExecutable</key>
  <string>LongPasteFix</string>
  <key>CFBundleIdentifier</key>
  <string>dev.jeffjung.longpastefix</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Long Paste Fix</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.2.1</string>
  <key>CFBundleVersion</key>
  <string>22</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

swiftc "$root_dir/Sources/IMESafeAI/main.swift" -o "$macos_dir/LongPasteFix" -framework AppKit

cp "$root_dir/README.md" "$resources_dir/README.md"
cp "$root_dir/LICENSE" "$resources_dir/LICENSE"
cp "$root_dir/assets/AppIcon.icns" "$resources_dir/AppIcon.icns"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$app_dir"
fi

zip_path="$dist_dir/long-paste-fix-macos.zip"
(
  cd "$dist_dir"
  ditto -c -k --sequesterRsrc --keepParent "$app_name.app" "$zip_path"
)

printf 'Built app: %s\n' "$app_dir"
printf 'Built zip: %s\n' "$zip_path"
