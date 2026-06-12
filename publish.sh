#!/usr/bin/env bash
set -euo pipefail

# Bump the version in Resources/Info.plist, optionally commit and push, then
# build the universal app and publish it as a GitHub release asset.
# Requires: gh (authenticated), make, swiftc.
# Usage: ./publish.sh

PLIST="Resources/Info.plist"
APP="build/Macxelio.app"

# ─── Validate ───

if [[ ! -f "$PLIST" ]]; then
    echo "Error: $PLIST not found (run from repo root)"
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is required"
    exit 1
fi

plist() { /usr/libexec/PlistBuddy -c "$1" "$PLIST"; }

# ─── Parse current version ───

CURRENT=$(plist "Print :CFBundleShortVersionString")
IFS='.' read -r MAJOR MINOR PATCH <<<"$CURRENT"
MAJOR=${MAJOR:-0}
MINOR=${MINOR:-0}
PATCH=${PATCH:-0}

# ─── Prompt: bump ───

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

# ─── Apply bump ───

if [[ "$VERSION" != "$CURRENT" ]]; then
    plist "Set :CFBundleShortVersionString ${VERSION}"
    plist "Set :CFBundleVersion ${VERSION}"
    echo ""
    echo "==> ${CURRENT} → ${VERSION}"
fi

# ─── Prompt: action ───

BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo ""
echo "  0) skip"
echo "  1) push     → commit (if changes) and push to origin/${BRANCH}"
echo "  2) release  → build, push, and publish GitHub release ${VERSION}"
echo ""
read -rp "Select action [0-2]: " action
action="${action:-0}"

if [[ "$action" == "0" ]]; then
    exit 0
fi

# ─── Commit & push ───

git add "$PLIST"
if ! git diff --cached --quiet; then
    git commit -m "chore: bump version to ${VERSION}"
fi

git push origin "$BRANCH"
echo ""
echo "==> Pushed ${BRANCH}"

if [[ "$action" != "2" ]]; then
    exit 0
fi

# ─── Build artifact ───

echo ""
echo "==> Building universal release..."
make release

ZIP="build/Macxelio-${VERSION}.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "==> Packaged ${ZIP}"

# ─── Publish GitHub release ───

if gh release view "$VERSION" >/dev/null 2>&1; then
    echo ""
    echo "Warning: release ${VERSION} already exists"
    read -rp "Delete existing release+tag and re-create at ${BRANCH}? [y/N]: " confirm
    case "$confirm" in
        y | Y) ;;
        *) exit 1 ;;
    esac
    gh release delete "$VERSION" --yes --cleanup-tag
    git tag -d "$VERSION" 2>/dev/null || true
    git fetch origin --prune --prune-tags >/dev/null 2>&1 || true
    echo "==> Deleted existing release ${VERSION}"
fi

gh release create "$VERSION" "$ZIP" \
    --title "$VERSION" \
    --target "$BRANCH" \
    --generate-notes
echo ""
echo "==> Published release ${VERSION}"
