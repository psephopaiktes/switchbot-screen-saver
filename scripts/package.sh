#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_root="${SAVER_DERIVED_DATA:-$repo_root/DerivedData}"
output_root="${1:-$repo_root/build}"
mkdir -p "$output_root"
staging="$(mktemp -d "$output_root/package.XXXXXX")"
trap 'rm -rf "$staging"' EXIT

xcodebuild -project "$repo_root/SwitchBotScreenSaver.xcodeproj" \
  -scheme SwitchBotScreenSaver -configuration Release \
  -derivedDataPath "$build_root" build

saver="$build_root/Build/Products/Release/SwitchBotScreenSaver.saver"
/usr/bin/codesign --verify --deep --strict "$saver"
xcrun swiftc -parse-as-library "$repo_root/scripts/verify-bundle.swift" -o "$staging/verify-bundle"
"$staging/verify-bundle" "$saver"

/usr/bin/ditto "$saver" "$staging/SwitchBotScreenSaver.saver"
COPYFILE_DISABLE=1 /usr/bin/tar -czf "$output_root/SwitchBotScreenSaver-macos.tar.gz" \
  -C "$staging" SwitchBotScreenSaver.saver
echo "作成: $output_root/SwitchBotScreenSaver-macos.tar.gz"
