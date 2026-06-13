#!/usr/bin/env bash
set -euo pipefail

# Bump the version, merge the current branch into main, push, and publish the
# universal app as a GitHub release from main.
# Requires: gh (authenticated), make, swiftc.
# Usage: ./publish.sh

PLIST="Resources/Info.plist"
APP="build/Macxelio.app"
MAIN="main"

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
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# ─── Confirm ───

echo ""
echo "Release ${VERSION}: merge ${BRANCH} → ${MAIN}, push, and publish."
read -rp "Continue? [y/N]: " confirm
case "$confirm" in
    y | Y) ;;
    *) exit 0 ;;
esac

# ─── Apply bump ───

if [[ "$VERSION" != "$CURRENT" ]]; then
    plist "Set :CFBundleShortVersionString ${VERSION}"
    plist "Set :CFBundleVersion ${VERSION}"
    echo "==> ${CURRENT} → ${VERSION}"
fi

# ─── Commit & push current branch ───

git add "$PLIST"
if ! git diff --cached --quiet; then
    git commit -m "chore: bump version to ${VERSION}"
fi
git push origin "$BRANCH"

# ─── Merge into main and push ───

git checkout "$MAIN"
git merge "$BRANCH" --ff-only 2>/dev/null || git merge "$BRANCH" --no-edit
git push origin "$MAIN"
echo "==> Merged ${BRANCH} → ${MAIN}"

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
    gh release delete "$VERSION" --yes --cleanup-tag
    echo "==> Deleted existing release ${VERSION}"
fi

gh release create "$VERSION" "$ZIP" \
    --title "$VERSION" \
    --target "$MAIN" \
    --generate-notes
echo ""
echo "==> Published release ${VERSION}"

# ─── Back to working branch ───

git checkout "$BRANCH"
