#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN=0

if [ "${1-}" = "--dry-run" ] || [ "${1-}" = "-n" ]; then
  DRY_RUN=1
fi

echo "[fix-unused-imports] Running in: $ROOT_DIR"
cd "$ROOT_DIR"

if command -v flutter >/dev/null 2>&1; then
  echo "[fix-unused-imports] Running: flutter pub get"
  flutter pub get
else
  echo "[fix-unused-imports] flutter not found in PATH, running 'dart pub get'"
  dart pub get
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[fix-unused-imports] Dry run: dart fix --dry-run"
  dart fix --dry-run
else
  echo "[fix-unused-imports] Applying fixes: dart fix --apply"
  dart fix --apply
fi

echo "[fix-unused-imports] Done. Use --dry-run to preview changes."
