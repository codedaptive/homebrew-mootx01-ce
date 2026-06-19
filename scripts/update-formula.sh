#!/usr/bin/env bash
#
# scripts/update-formula.sh
#
# Update Formula/mootx01.rb with the SHA256 checksums and version from a
# GitHub release. Run this immediately after tagging and waiting for the
# release workflow to attach assets.
#
# Usage:
#   ./scripts/update-formula.sh                  # latest release
#   ./scripts/update-formula.sh v1.0.4-beta      # specific tag
#
# Requirements: curl, shasum (macOS) or sha256sum (Linux), sed, gh (optional)
#
set -euo pipefail

REPO="codedaptive/mootx01-ce"
FORMULA="Formula/mootx01.rb"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMULA_PATH="$SCRIPT_DIR/../$FORMULA"

# ── 1. Resolve version ────────────────────────────────────────────────────
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "Resolving latest release from $REPO..."
  VERSION="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    "https://github.com/$REPO/releases/latest" \
    | sed -n 's#.*/releases/tag/##p' | tr -d '\r')"
fi
# Normalise: ensure leading 'v'
case "$VERSION" in v*) ;; *) VERSION="v$VERSION" ;; esac
# Strip leading 'v' for the formula version field
VERSION_BARE="${VERSION#v}"

echo "Updating formula for $VERSION..."

# ── 2. Download and hash each asset ───────────────────────────────────────
BASE_URL="https://github.com/$REPO/releases/download/$VERSION"

declare -A ASSETS=(
  ["macos-arm64"]="mootx01-${VERSION}-macos-arm64.tar.gz"
  ["macos-x86_64"]="mootx01-${VERSION}-macos-x86_64.tar.gz"
  ["linux-x86_64"]="mootx01-${VERSION}-linux-x86_64.tar.gz"
  ["linux-arm64"]="mootx01-${VERSION}-linux-arm64.tar.gz"
)

declare -A SHA256S

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for KEY in "${!ASSETS[@]}"; do
  ASSET="${ASSETS[$KEY]}"
  URL="$BASE_URL/$ASSET"
  echo "  Downloading $ASSET..."
  curl -fsSL "$URL" -o "$TMP/$ASSET" || {
    echo "  ✗ Could not download $URL — skipping $KEY"
    SHA256S[$KEY]="0000000000000000000000000000000000000000000000000000000000000000"
    continue
  }
  if command -v shasum &>/dev/null; then
    SHA256S[$KEY]="$(shasum -a 256 "$TMP/$ASSET" | awk '{print $1}')"
  else
    SHA256S[$KEY]="$(sha256sum "$TMP/$ASSET" | awk '{print $1}')"
  fi
  echo "  ✓ ${KEY}: ${SHA256S[$KEY]}"
done

# ── 3. Write the updated formula ──────────────────────────────────────────
# Strategy: rewrite the formula from scratch using the current file as the
# template but with version and sha256 values replaced inline.
# sed -i handles both macOS (BSD) and Linux (GNU) via the empty-string form.

# Version
sed -i '' "s/^  version \".*\"/  version \"${VERSION_BARE}\"/" "$FORMULA_PATH"

# SHA256s — each is the only sha256 on its respective on_arm/on_intel block.
# We replace occurrences in order: arm (first on_arm = macOS arm), intel
# (first on_intel = macOS intel), then linux intel, then linux arm.
# Use a Python one-liner for reliable nth-occurrence replacement.
python3 - "$FORMULA_PATH" \
  "${SHA256S[macos-arm64]}" \
  "${SHA256S[macos-x86_64]}" \
  "${SHA256S[linux-x86_64]}" \
  "${SHA256S[linux-arm64]}" \
  <<'PYEOF'
import sys, re

path, arm_mac, intel_mac, intel_linux, arm_linux = sys.argv[1:]
targets = [arm_mac, intel_mac, intel_linux, arm_linux]

with open(path) as f:
    text = f.read()

idx = 0
def replacer(m):
    global idx
    replacement = '      sha256 "' + targets[idx] + '"'
    idx += 1
    return replacement

text = re.sub(r'      sha256 "[0-9a-f]+"', replacer, text)

with open(path, 'w') as f:
    f.write(text)
PYEOF

echo ""
echo "Formula updated: $FORMULA"
echo ""
echo "Next steps:"
echo "  cd $(dirname "$FORMULA_PATH")"
echo "  git add $FORMULA"
echo "  git commit -m \"formula: update to $VERSION\""
echo "  git tag $VERSION"
echo "  git push origin main --tags"
