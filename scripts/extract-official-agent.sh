#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP="${1:-${ABB_OFFICIAL_ZIP:-}}"

if [ -z "$ZIP" ] || [ ! -f "$ZIP" ]; then
    echo "Usage: ABB_OFFICIAL_ZIP=/path/to/official.zip $0" >&2
    echo "   or: $0 /path/to/official.zip" >&2
    exit 1
fi

mkdir -p "$ROOT_DIR/build/manual-extract"
unzip -q "$ZIP" -d "$ROOT_DIR/build/manual-extract"
find "$ROOT_DIR/build/manual-extract" -type f -name '*.deb' -print

