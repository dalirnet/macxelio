#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
APP="build/Macxelio.app"

build_arch() {
    find Sources -name '*.swift' -print0 | xargs -0 swiftc "$2" -o "$1" \
        -framework SwiftUI -framework AppKit -framework Network \
        -target "$3-apple-macos13.0"
}

echo "Building ${CONFIG}..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

case "$CONFIG" in
    debug)
        build_arch "$APP/Contents/MacOS/Macxelio" -g "$(uname -m)"
        ;;
    release)
        build_arch build/Macxelio_arm64 -O arm64
        build_arch build/Macxelio_x86_64 -O x86_64
        lipo -create -output "$APP/Contents/MacOS/Macxelio" build/Macxelio_arm64 build/Macxelio_x86_64
        rm build/Macxelio_arm64 build/Macxelio_x86_64
        ;;
    *)
        echo "Usage: $0 [debug|release]"
        exit 1
        ;;
esac

cp Resources/Info.plist "$APP/Contents/"
cp Resources/AppIcon.icns Resources/helper.sh "$APP/Contents/Resources/"

echo "Done: $APP"
