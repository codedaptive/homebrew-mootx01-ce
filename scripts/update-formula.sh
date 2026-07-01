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
# Portability: must run on both macOS (default bash 3.2, no associative
# arrays) and Linux CI (GNU coreutils). We therefore avoid `declare -A`
# entirely and do all in-file edits in Python — never `sed -i`, whose
# in-place syntax differs incompatibly between BSD (`-i ''`) and GNU (`-i`).
#
# Requirements: curl, shasum (macOS) or sha256sum (Linux), python3
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

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Download the named asset and print its SHA-256 on stdout. Progress goes to
# stderr so command substitution captures only the hash. A missing asset
# yields the 64-zero placeholder, which Homebrew rejects at install — a
# broken download must fail loud, never silently ship a stale/wrong hash.
hash_asset() {
  local asset="$1"
  local url="$BASE_URL/$asset"
  echo "  Downloading $asset..." >&2
  if ! curl -fsSL "$url" -o "$TMP/$asset"; then
    echo "  ✗ Could not download $url" >&2
    echo "0000000000000000000000000000000000000000000000000000000000000000"
    return
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$TMP/$asset" | awk '{print $1}'
  else
    sha256sum "$TMP/$asset" | awk '{print $1}'
  fi
}

# Four ordered variables (no associative arrays, for bash 3.2). The order
# here MUST match the order the sha256 lines appear in the formula: macOS
# arm, macOS intel, Linux intel, Linux arm (see the Python step below).
SHA_MACOS_ARM64="$(hash_asset "mootx01-${VERSION}-macos-arm64.tar.gz")"
echo "  ✓ macos-arm64:  $SHA_MACOS_ARM64"
SHA_MACOS_X86_64="$(hash_asset "mootx01-${VERSION}-macos-x86_64.tar.gz")"
echo "  ✓ macos-x86_64: $SHA_MACOS_X86_64"
SHA_LINUX_X86_64="$(hash_asset "mootx01-${VERSION}-linux-x86_64.tar.gz")"
echo "  ✓ linux-x86_64: $SHA_LINUX_X86_64"
SHA_LINUX_ARM64="$(hash_asset "mootx01-${VERSION}-linux-arm64.tar.gz")"
echo "  ✓ linux-arm64:  $SHA_LINUX_ARM64"

# ── 3. Write the updated formula ──────────────────────────────────────────
# All in-file edits happen here in Python: the version field plus the four
# sha256 lines, replaced in document order. Python is already required and
# is byte-identical across macOS and Linux, so there is no BSD-vs-GNU sed
# hazard.
python3 - "$FORMULA_PATH" \
  "$VERSION_BARE" \
  "$SHA_MACOS_ARM64" \
  "$SHA_MACOS_X86_64" \
  "$SHA_LINUX_X86_64" \
  "$SHA_LINUX_ARM64" \
  <<'PYEOF'
import sys, re

path, version, arm_mac, intel_mac, intel_linux, arm_linux = sys.argv[1:]
targets = [arm_mac, intel_mac, intel_linux, arm_linux]

with open(path) as f:
    text = f.read()

# version "X.Y.Z" — the single 2-space-indented version line.
text, n = re.subn(r'^  version ".*"', '  version "' + version + '"',
                  text, count=1, flags=re.M)
if n != 1:
    sys.exit("expected exactly one version line, replaced %d" % n)

# The four sha256 lines, in document order (macOS arm, macOS intel,
# Linux intel, Linux arm).
idx = 0
def replacer(m):
    global idx
    out = '      sha256 "' + targets[idx] + '"'
    idx += 1
    return out

text, n = re.subn(r'      sha256 "[0-9a-f]+"', replacer, text)
if n != 4:
    sys.exit("expected exactly four sha256 lines, replaced %d" % n)

with open(path, 'w') as f:
    f.write(text)
PYEOF

echo ""
echo "Formula updated: $FORMULA"
echo ""
echo "Next steps:"
echo "  git add $FORMULA"
echo "  git commit -m \"formula: update to $VERSION\""
echo "  git push origin main"
