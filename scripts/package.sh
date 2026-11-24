#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:?Usage: $0 <version>}"
ZIP="build/Macxelio-${VERSION}.zip"

rm -f "$ZIP"
ditto -c -k --keepParent build/Macxelio.app "$ZIP"

echo "Done: $ZIP"
