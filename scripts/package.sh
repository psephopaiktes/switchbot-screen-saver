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

mkdir -p "$staging/SwitchBotScreenSaver"
/usr/bin/ditto "$saver" "$staging/SwitchBotScreenSaver/SwitchBotScreenSaver.saver"
cp "$repo_root/docs/INSTALL.md" "$staging/SwitchBotScreenSaver/はじめに.md"
cp "$repo_root/docs/INSTALL.en.md" "$staging/SwitchBotScreenSaver/Getting Started.md"
/usr/bin/ditto -c -k --keepParent "$staging/SwitchBotScreenSaver" "$output_root/SwitchBotScreenSaver-macos.zip"
echo "作成: $output_root/SwitchBotScreenSaver-macos.zip"
