#!/bin/zsh
# Builds RNKCDoneGlass.app for the iOS simulator and installs + launches it.
# Usage: ./build.sh [simulator UDID or name]   (default: booted)
#        XCODE="/Applications/Xcode 27.app" ./build.sh   to pick a toolchain
set -eu
cd "${0:A:h}"

export DEVELOPER_DIR="${XCODE:-/Applications/Xcode.app}/Contents/Developer"
device="${1:-booted}"
app=build/RNKCDoneGlass.app

rm -rf "$app"
mkdir -p "$app"
cp Info.plist "$app/"

xcrun --sdk iphonesimulator swiftc \
  -parse-as-library \
  -target arm64-apple-ios26.0-simulator \
  -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  Sources/*.swift vendor/rnkc-1.22.8/*.swift vendor/rnkc-glass-prop/*.swift \
  -o "$app/RNKCDoneGlass"

codesign -s - --force "$app" >/dev/null
xcrun simctl install "$device" "$app"
xcrun simctl launch "$device" com.example.rnkc-done-glass
