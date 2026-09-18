#!/usr/bin/env bash
# Publish (or update) one prospect asset set at the repeatable path
#   https://risen-digital.github.io/see/{slug}/
#
# This is the template mechanism for outbound freeze-gate item 3: every
# prospect's asset set (pitch page + homepage rebuild) is served as a
# single static HTML file at see/{slug}/index.html, with a noindex robots
# meta tag enforced automatically. No manual GitHub UI upload needed.
#
# Usage:
#   scripts/publish-asset-set.sh <slug> <path-to-html-file> [--push]
#
# Example:
#   scripts/publish-asset-set.sh acme-nonprofit ./drafts/acme.html --push
#
# Source of the HTML is whatever produced the asset set this run — today
# that is hand-authored / agent-drafted content pulled from a published
# agentful-artifact (see prospect-asset-set-v1 for the reference shape:
# Part 1 pitch letter, Part 2 homepage rebuild in an iframe, Part 3 video
# note). When the RisenDigitalSite AI generation pipeline (blocked on
# commitment risensite-ai-pipeline-keys) is unblocked, its output can be
# piped into this same script — the publish step does not care how the
# HTML was produced.

set -euo pipefail

SLUG="${1:?usage: publish-asset-set.sh <slug> <path-to-html-file> [--push]}"
SRC="${2:?usage: publish-asset-set.sh <slug> <path-to-html-file> [--push]}"
PUSH="${3:-}"

if [[ ! "$SLUG" =~ ^[a-z0-9-]+$ ]]; then
  echo "error: slug must be lowercase letters, digits, and hyphens only (got: $SLUG)" >&2
  exit 1
fi

if [[ ! -f "$SRC" ]]; then
  echo "error: source file not found: $SRC" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="$REPO_ROOT/see/$SLUG"
DEST_FILE="$DEST_DIR/index.html"

mkdir -p "$DEST_DIR"

if grep -qi 'name="robots"' "$SRC"; then
  cp "$SRC" "$DEST_FILE"
else
  # Inject the noindex meta tag right after the first <head> if the source
  # doesn't already carry one — these pages are for one named recipient,
  # never for crawlers.
  awk '
    { print }
    tolower($0) ~ /<head[ >]/ && !done {
      print "<meta name=\"robots\" content=\"noindex, nofollow, noarchive, nosnippet\">"
      done = 1
    }
  ' "$SRC" > "$DEST_FILE"
fi

echo "Published: see/$SLUG/index.html"
echo "Will be live at: https://risen-digital.github.io/see/$SLUG/ (after next Pages build, ~1-2 min)"

if [[ "$PUSH" == "--push" ]]; then
  cd "$REPO_ROOT"
  git add "see/$SLUG/index.html"
  git commit -m "Publish prospect asset set: $SLUG"
  git push
  echo "Pushed. GitHub Pages will rebuild automatically."
fi
