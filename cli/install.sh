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
#   ECV_TF_NO_MODIFY_PATH=1   don't add PREFIX to your shell startup file
#
# If PREFIX isn't on your PATH, one `export PATH=...` line is appended to
# ~/.zshrc (zsh), ~/.bash_profile / ~/.bashrc (bash) or ~/.profile (others).
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

# Put PREFIX on the PATH for future terminals by adding one line to the shell's
# startup file. (An `export` here alone would vanish when this script exits.)
case ":$PATH:" in
  *":$PREFIX:"*) exit 0;;   # already on PATH
esac

case "$PREFIX" in
  "$HOME"/*) path_dir="\$HOME/${PREFIX#"$HOME"/}";;
  *)         path_dir="$PREFIX";;
esac
path_line="export PATH=\"$path_dir:\$PATH\""

case "$(basename "${SHELL:-}")" in
  zsh)  rc="${ZDOTDIR:-$HOME}/.zshrc";;
  bash) if [ "$(uname)" = "Darwin" ]; then rc="$HOME/.bash_profile"; else rc="$HOME/.bashrc"; fi;;
  *)    rc="$HOME/.profile";;
esac

echo ""
if [ "${ECV_TF_NO_MODIFY_PATH:-}" = "1" ]; then
  echo "$PREFIX is not on your PATH. Add this line to $rc:"
  echo "  $path_line"
elif [ -f "$rc" ] && { grep -qF "$path_line" "$rc" || grep -qF "$PREFIX" "$rc"; }; then
  echo "$rc already adds $PREFIX to PATH — open a new terminal (or: source $rc)."
else
  printf '\n# Added by the ecv-tf installer\n%s\n' "$path_line" >> "$rc"
  echo "Added $PREFIX to PATH in $rc"
  echo "Open a new terminal, or run:  source $rc"
fi
