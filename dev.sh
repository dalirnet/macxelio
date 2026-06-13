#!/usr/bin/env bash
set -euo pipefail

# dev.sh [debug|release|publish]
#   debug    (default) build a debug app for the host architecture
#   release            build a universal release app
#   publish            bump the version, merge into main, push, and publish a
#                      GitHub release from main
# Requires: swiftc; publish also needs gh (authenticated).

PLIST="Resources/Info.plist"
APP="build/Macxelio.app"
MAIN="main"

if [[ ! -f "$PLIST" ]]; then
    echo "Error: $PLIST not found (run from repo root)"
    exit 1
fi

# ─── Build ───

build_arch() {
    swiftc ${2} -o ${1} \
        Sources/*.swift \
        Sources/Models/*.swift \
        Sources/Services/*.swift \
        Sources/Components/*.swift \
        Sources/Views/*.swift \
        Sources/Utils/*.swift \
        Sources/StatusBar/*.swift \
        -framework SwiftUI -framework AppKit -framework Network \
        -target ${3}-apple-macos13.0
}

build() {
    local config="${1:-debug}"
    echo "Building ${config}..."

    mkdir -p build/Macxelio.app/Contents/{MacOS,Resources}

    if [ "$config" = "release" ]; then
        build_arch build/Macxelio_arm64 "-O" "arm64"
        build_arch build/Macxelio_x86_64 "-O" "x86_64"
        lipo -create -output build/Macxelio.app/Contents/MacOS/Macxelio build/Macxelio_{arm64,x86_64}
        rm build/Macxelio_{arm64,x86_64}
    else
        build_arch build/Macxelio.app/Contents/MacOS/Macxelio "-g" "$(uname -m)"
    fi

    cp Resources/Info.plist build/Macxelio.app/Contents/
    cp Resources/AppIcon.icns build/Macxelio.app/Contents/Resources/

    echo "Done: build/Macxelio.app"
}

# ─── Publish ───

plist() { /usr/libexec/PlistBuddy -c "$1" "$PLIST"; }

publish() {
    if ! command -v gh >/dev/null 2>&1; then
        echo "Error: GitHub CLI (gh) is required"
        exit 1
    fi

    local CURRENT MAJOR MINOR PATCH VERSION BRANCH choice confirm ZIP
    CURRENT=$(plist "Print :CFBundleShortVersionString")
    IFS='.' read -r MAJOR MINOR PATCH <<<"$CURRENT"
    MAJOR=${MAJOR:-0}
    MINOR=${MINOR:-0}
    PATCH=${PATCH:-0}

    echo "Current version: ${CURRENT}"
    echo ""
    echo "  0) skip    → ${MAJOR}.${MINOR}.${PATCH}"
    echo "  1) patch   → ${MAJOR}.${MINOR}.$((PATCH + 1))"
    echo "  2) minor   → ${MAJOR}.$((MINOR + 1)).0"
    echo "  3) major   → $((MAJOR + 1)).0.0"
    echo ""
    read -rp "Select bump type [0-3]: " choice

    case "${choice:-0}" in
        0) ;;
        1) PATCH=$((PATCH + 1)) ;;
        2) MINOR=$((MINOR + 1)); PATCH=0 ;;
        3) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
        *) echo "Error: invalid choice"; exit 1 ;;
    esac

    VERSION="${MAJOR}.${MINOR}.${PATCH}"
    BRANCH=$(git rev-parse --abbrev-ref HEAD)

    echo ""
    echo "Release ${VERSION}: merge ${BRANCH} → ${MAIN}, push, and publish."
    read -rp "Continue? [y/N]: " confirm
    case "$confirm" in
        y | Y) ;;
        *) exit 0 ;;
    esac

    if [[ "$VERSION" != "$CURRENT" ]]; then
        plist "Set :CFBundleShortVersionString ${VERSION}"
        plist "Set :CFBundleVersion ${VERSION}"
        echo "==> ${CURRENT} → ${VERSION}"
    fi

    git add "$PLIST"
    if ! git diff --cached --quiet; then
        git commit -m "chore: bump version to ${VERSION}"
    fi
    git push origin "$BRANCH"

    git checkout "$MAIN"
    git fetch origin "$MAIN"
    git reset --hard "origin/$MAIN"
    git merge "$BRANCH" --ff-only 2>/dev/null || git merge "$BRANCH" --no-edit
    git push origin "$MAIN"
    echo "==> Merged ${BRANCH} → ${MAIN}"

    echo ""
    build release

    ZIP="build/Macxelio-${VERSION}.zip"
    rm -f "$ZIP"
    ditto -c -k --keepParent "$APP" "$ZIP"
    echo "==> Packaged ${ZIP}"

    if gh release view "$VERSION" >/dev/null 2>&1; then
        gh release delete "$VERSION" --yes --cleanup-tag
        echo "==> Deleted existing release ${VERSION}"
    fi

    gh release create "$VERSION" "$ZIP" \
        --title "$VERSION" \
        --target "$MAIN" \
        --generate-notes
    echo ""
    echo "==> Published release ${VERSION}"

    git checkout "$BRANCH"
}

# ─── Dispatch ───

case "${1:-debug}" in
    debug) build debug ;;
    release) build release ;;
    publish) publish ;;
    *) echo "Usage: $0 [debug|release|publish]"; exit 1 ;;
esac
