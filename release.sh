#!/usr/bin/env bash
#
# release.sh - Parts Bin Label Generator release automation
#
# Usage:   ./release.sh <version> ["release summary line"] [--no-push]
# Example: ./release.sh 105 "Added torx security bit variant"
#          ./release.sh 105 "Added torx variant" --no-push   # push via GitHub Desktop
#
# What it does:
#   1. Copies the newest downloaded release files from ~/Downloads into this repo:
#        imperial_v<N>.scad        -> imperial.scad
#        metric_v<N>.scad          -> metric.scad
#        master_specification.md   -> SPECIFICATION.md
#        v<N>_changes_summary.md   -> RELEASE_NOTES.md (new entry inserted
#                                      below the header, newest first)
#   2. Verifies both .scad files carry the expected version header
#   3. Commits, tags v<N>, and pushes (commits + tags)
#
# Setup (one time): place this script in the repo root, chmod +x release.sh
# Requires: git configured with push access to the repo (SSH key or
# credential manager - the script never handles credentials itself).

set -euo pipefail

# --- locate the Downloads folder (WSL-aware) ---
# On WSL, browser downloads land in the *Windows* Downloads folder, not the
# Linux home. Auto-detect it; override anytime with:  DOWNLOADS=/path ./release.sh ...
if [[ -z "${DOWNLOADS:-}" ]]; then
  if grep -qi microsoft /proc/version 2>/dev/null; then
    WINHOME="$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' || true)"
    if [[ -n "$WINHOME" ]]; then
      DOWNLOADS="$(wslpath "$WINHOME")/Downloads"
    else
      # Fallback: newest-modified Downloads folder under /mnt/c/Users
      DOWNLOADS="$(ls -dt /mnt/c/Users/*/Downloads 2>/dev/null | head -1)"
    fi
  fi
  DOWNLOADS="${DOWNLOADS:-$HOME/Downloads}"
fi
echo "Downloads folder: $DOWNLOADS"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"
SRC_DIR="$DOWNLOADS"

# --- args ---
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <version-number> [\"summary line\"] [--no-push]" >&2
  exit 1
fi
VER="$1"
SUMMARY="Release v$VER"
NO_PUSH=0
shift
for arg in "$@"; do
  if [[ "$arg" == "--no-push" ]]; then NO_PUSH=1; else SUMMARY="$arg"; fi
done

if ! [[ "$VER" =~ ^[0-9]+$ ]]; then
  echo "ERROR: version must be a whole integer (got '$VER')" >&2
  exit 1
fi

# --- sanity: repo state ---
if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: repo has uncommitted changes. Commit or stash first." >&2
  exit 1
fi
git pull --ff-only

# --- prefer the versioned release bundle if present ---
BUNDLE="$(ls -t "$DOWNLOADS"/gridfinity-labels-v${VER}*.zip 2>/dev/null | head -1)"
if [[ -n "$BUNDLE" ]]; then
  SRC_DIR="$(mktemp -d)"
  trap 'rm -rf "$SRC_DIR"' EXIT
  unzip -q -o -j "$BUNDLE" -d "$SRC_DIR"
  echo "Using bundle: $(basename "$BUNDLE")"
fi

# --- locate release files (newest match wins if duplicates exist) ---
find_newest() {
  ls -t "$SRC_DIR"/$1 2>/dev/null | head -1
}

IMP_SRC="$(find_newest "imperial_v${VER}*.scad")"
MET_SRC="$(find_newest "metric_v${VER}*.scad")"
SPEC_SRC="$(find_newest "master_specification*.md")"
NOTES_SRC="$(find_newest "v${VER}_changes_summary*.md")"

[[ -n "$IMP_SRC" ]] || { echo "ERROR: imperial_v${VER}.scad not found in $SRC_DIR" >&2; exit 1; }
[[ -n "$MET_SRC" ]] || { echo "ERROR: metric_v${VER}.scad not found in $SRC_DIR" >&2; exit 1; }

# --- verify version headers before touching the repo ---
for f in "$IMP_SRC" "$MET_SRC"; do
  if ! grep -q "Version ${VER} " "$f"; then
    echo "ERROR: $f does not contain 'Version ${VER}' header - wrong file?" >&2
    exit 1
  fi
done

# --- copy into repo (ensure trailing newline on .scad files) ---
copy_with_newline() {
  cp "$1" "$2"
  [[ -n "$(tail -c1 "$2")" ]] && echo >> "$2"
}
copy_with_newline "$IMP_SRC" imperial.scad
copy_with_newline "$MET_SRC" metric.scad
echo "Copied: $(basename "$IMP_SRC") -> imperial.scad"
echo "Copied: $(basename "$MET_SRC") -> metric.scad"

if [[ -n "$SPEC_SRC" ]]; then
  cp "$SPEC_SRC" SPECIFICATION.md
  echo "Copied: $(basename "$SPEC_SRC") -> SPECIFICATION.md"
else
  echo "NOTE: no master_specification*.md in bundle/Downloads - spec unchanged"
fi

if [[ -n "$NOTES_SRC" ]]; then
  # Insert new entry into RELEASE_NOTES.md below the file header (newest first).
  # The changes summary's own "# Version N ..." title is demoted to "## vN ..."
  # so entries nest correctly under the single "# Release Notes" H1.
  if [[ ! -f RELEASE_NOTES.md ]]; then
    printf '# Release Notes\n\nNewest releases first. Each entry corresponds to a git tag (`vNNN`).\n' > RELEASE_NOTES.md
  fi
  # Demote every heading one level (# -> ##, ## -> ###, ...) so the
  # summary nests under the single "# Release Notes" H1
  sed 's/^#/##/' "$NOTES_SRC" > .notes_entry.tmp
  # Split existing file: header = everything before the first "## " entry
  awk '/^## /{exit} {print}' RELEASE_NOTES.md > .notes_head.tmp
  awk 'f{print} /^## /{if(!f){f=1; print}}' RELEASE_NOTES.md > .notes_rest.tmp
  # Strip trailing blank lines and --- separators from the header, then re-add one
  tac .notes_head.tmp | awk 'f || ($0 !~ /^(---)?[[:space:]]*$/) {f=1; print}' | tac > .notes_head2.tmp
  { cat .notes_head2.tmp; echo; echo "---"; echo; cat .notes_entry.tmp; echo; cat .notes_rest.tmp; } > RELEASE_NOTES.md
  rm -f .notes_head.tmp .notes_head2.tmp .notes_rest.tmp .notes_entry.tmp
  echo "Inserted: $(basename "$NOTES_SRC") -> RELEASE_NOTES.md"
fi

# --- commit, tag, push ---
git add imperial.scad metric.scad RELEASE_NOTES.md
[[ -f SPECIFICATION.md ]] && git add SPECIFICATION.md
# Retire the old plain-text notes file if it still exists
[[ -f release_notes.txt ]] && git rm -q release_notes.txt

git commit -m "v${VER}: ${SUMMARY}"
git tag -a "v${VER}" -m "v${VER}: ${SUMMARY}"

if [[ "$NO_PUSH" == "1" ]]; then
  echo ""
  echo "=== v${VER} committed and tagged locally (not pushed) ==="
  echo "Next: push in GitHub Desktop (Repository menu > Push, which includes tags),"
  echo "then click 'Sync now' on the Claude project's GitHub source."
else
  git push
  git push origin "v${VER}"
  echo ""
  echo "=== Released v${VER} ==="
  echo "Don't forget: open the Claude project and click 'Sync now' on the GitHub source."
fi
