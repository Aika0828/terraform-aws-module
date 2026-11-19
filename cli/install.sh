#!/usr/bin/env bash
#
# install.sh — install the ecv-tf CLI.
#
#   From a clone of the library:   ./cli/install.sh
#   Without a clone:               bash install.sh        (fetches the latest release)
#
# Environment:
#   PREFIX        install dir (default: ~/.local/bin)
#   ECV_TF_REPO   library repo to fetch from when not run from a clone
#   ECV_TF_REF    release to fetch (default: latest vX.Y.Z tag)
#
set -eo pipefail

PREFIX="${PREFIX:-$HOME/.local/bin}"
REPO="${ECV_TF_REPO:-git@gitlab.ecvmsp.com:ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git}"
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [ -n "$here" ] && [ -f "$here/ecv-tf" ]; then
  src="$here/ecv-tf"
  echo "Installing ecv-tf from $src"
else
  command -v git >/dev/null 2>&1 || { echo "error: git is required" >&2; exit 1; }
  echo "Fetching ecv-tf from $REPO ..."
  git clone --quiet --no-checkout --filter=blob:none "$REPO" "$tmp/repo" 2>/dev/null \
    || { echo "error: could not clone $REPO (check your SSH key / token, or set ECV_TF_REPO)" >&2; exit 1; }
  ref="${ECV_TF_REF:-$(git -C "$tmp/repo" tag -l | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' \
        | awk '{ s=$0; sub(/^v/, "", s); split(s, a, "."); print a[1], a[2], a[3], $0 }' \
        | sort -k1,1n -k2,2n -k3,3n | awk 'END { print $4 }')}"
  [ -n "$ref" ] || { echo "error: no release tags found in $REPO" >&2; exit 1; }
  git -C "$tmp/repo" show "$ref:cli/ecv-tf" > "$tmp/ecv-tf" 2>/dev/null \
    || { echo "error: release $ref doesn't contain cli/ecv-tf" >&2; exit 1; }
  src="$tmp/ecv-tf"
  echo "Using release $ref"
fi

bash -n "$src"
mkdir -p "$PREFIX"
cp "$src" "$PREFIX/ecv-tf"
chmod 755 "$PREFIX/ecv-tf"
echo "Installed: $PREFIX/ecv-tf  ($("$PREFIX/ecv-tf" version))"

# Remember the repo the CLI was installed from, if it isn't the built-in default.
if [ -n "${ECV_TF_REPO:-}" ]; then
  "$PREFIX/ecv-tf" config set --global repo "$ECV_TF_REPO" >/dev/null
  echo "Set global repo = $ECV_TF_REPO"
fi

case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *) echo ""
     echo "Add $PREFIX to your PATH, e.g. in ~/.zshrc:"
     echo "  export PATH=\"$PREFIX:\$PATH\"";;
esac
