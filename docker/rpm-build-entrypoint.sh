#!/usr/bin/env bash
set -Eeuo pipefail

SRC_DIR="${ABB_SOURCE_DIR:-/work}"
RUN_BASE="${ABB_CONTAINER_RUN_BASE:-/tmp/abb-rpm-build}"
RUN_DIR="$RUN_BASE/work"
OUT_DIR="${ABB_OUTPUT_DIR:-$SRC_DIR/dist}"

if [ ! -f "$SRC_DIR/scripts/build-rpm.sh" ]; then
    echo "ERROR: expected project checkout at $SRC_DIR" >&2
    exit 1
fi

rm -rf "$RUN_BASE"
mkdir -p "$RUN_DIR" "$OUT_DIR"

tar \
    --exclude='./.git' \
    --exclude='./.codex' \
    --exclude='./build' \
    --exclude='./dist' \
    -C "$SRC_DIR" \
    -cf - . | tar -C "$RUN_DIR" -xf -

chown -R builder:builder "$RUN_BASE"

cd "$RUN_DIR"
runuser -u builder -- "$@"

if [ -d "$RUN_DIR/dist" ]; then
    cp -a "$RUN_DIR/dist/." "$OUT_DIR/"
fi

echo "RPM build artifacts copied to: $OUT_DIR"
