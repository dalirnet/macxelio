#!/bin/bash

CONFIG=${1:-debug}

if [ "$CONFIG" != "debug" ] && [ "$CONFIG" != "release" ]; then
    echo "Usage: $0 [debug|release]"
    exit 1
fi

echo "Building $CONFIG..."

mkdir -p build/Macxelio.app/Contents/{MacOS,Resources}

build_arch() {
    swiftc ${2} -o ${1} \
        Sources/MacxelioApp.swift Sources/Models/*.swift Sources/Utils/*.swift Sources/Views/*.swift \
        -framework SwiftUI -framework AppKit -target ${3}-apple-macos13.0
}

if [ "$CONFIG" = "release" ]; then
    build_arch build/Macxelio_arm64 "-O" "arm64"
    build_arch build/Macxelio_x86_64 "-O" "x86_64"
    lipo -create -output build/Macxelio.app/Contents/MacOS/Macxelio build/Macxelio_{arm64,x86_64}
    rm build/Macxelio_{arm64,x86_64}
else
    build_arch build/Macxelio.app/Contents/MacOS/Macxelio "-g" $(uname -m)
fi

cp Resources/Info.plist build/Macxelio.app/Contents/
cp Resources/AppIcon.icns build/Macxelio.app/Contents/Resources/

echo "Done: build/Macxelio.app"
