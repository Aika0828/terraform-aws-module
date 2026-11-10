#!/usr/bin/env bash
#
# fetch-modules.sh — vendor selected modules from the terraform-aws-modules
# monorepo into your project, using a shallow *sparse* checkout: only the module
# paths you ask for are downloaded, not the whole repository.
#
# Drop this file into any project (or `curl` it) and run it. It needs only git.
#
set -eo pipefail

REPO="${TFMOD_REPO:-git@gitlab.ecvmsp.com:ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git}"
REF="${TFMOD_REF:-v0.1.0}"
DEST="./vendor/terraform-aws-modules"
LIST=0
MODULES=()

usage() {
  cat <<'EOF'
fetch-modules.sh — vendor selected Terraform modules via a sparse checkout.

Usage:
  fetch-modules.sh [options] <module> [<module> ...]

<module> is a bare name (aws-vpc) or a domain/name path (networking/aws-vpc).
Bare names are resolved automatically; ambiguous ones are reported.

Options:
  -r, --repo URL   Git URL of the library        (env TFMOD_REPO)
  -t, --ref  REF   Tag/branch/commit to fetch     (env TFMOD_REF; default v0.1.0)
  -d, --dest DIR   Vendor destination             (default ./vendor/terraform-aws-modules)
  -l, --list       List available modules at REF and exit
  -h, --help       Show this help

Examples:
  fetch-modules.sh aws-vpc aws-ecs-cluster aws-ecs-service
  fetch-modules.sh -t v1.2.0 -d modules/_vendor database/aws-rds-aurora
  TFMOD_REPO=git@gitlab.ecvmsp.com:ecv-ph-tech-team/ph-modernization-team/terraform-aws-module.git fetch-modules.sh --list

After vendoring, reference a module locally, e.g.:
  module "vpc" {
    source = "./vendor/terraform-aws-modules/networking/aws-vpc"
    providers = { aws = aws.workload }
    ...
  }
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -r|--repo) REPO="$2"; shift 2;;
    -t|--ref)  REF="$2";  shift 2;;
    -d|--dest) DEST="$2"; shift 2;;
    -l|--list) LIST=1; shift;;
    -h|--help) usage; exit 0;;
    --) shift; while [ $# -gt 0 ]; do MODULES+=("$1"); shift; done;;
    -*) echo "error: unknown option: $1" >&2; usage >&2; exit 2;;
    *) MODULES+=("$1"); shift;;
  esac
done

command -v git >/dev/null 2>&1 || { echo "error: git is required" >&2; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Cloning $REPO @ $REF (metadata only)..." >&2
if ! git clone --no-checkout --filter=blob:none --depth 1 --branch "$REF" "$REPO" "$tmp" >/dev/null 2>&1; then
  echo "error: clone failed — check --repo, --ref (does the tag exist?) and your git access." >&2
  exit 1
fi

# Every module directory present at this ref (modules/<domain>/aws-<name>).
ALL="$(git -C "$tmp" ls-tree -d -r --name-only HEAD modules 2>/dev/null \
        | grep -E '^modules/[^/]+/aws-[^/]+$' | sort)"

if [ "$LIST" = "1" ]; then
  printf '%s\n' "$ALL" | sed 's#^modules/##'
  exit 0
fi

if [ "${#MODULES[@]}" -eq 0 ]; then
  echo "error: no modules requested." >&2; usage >&2; exit 2
fi

# Resolve each requested module to its full modules/<domain>/<name> path.
PATHS=()
for m in "${MODULES[@]}"; do
  case "$m" in
    */*) match="$(printf '%s\n' "$ALL" | grep -Fx "modules/$m" || true)";;
    *)   match="$(printf '%s\n' "$ALL" | grep -E "/$m\$" || true)";;
  esac
  n="$(printf '%s\n' "$match" | grep -c . || true)"
  if [ "$n" -eq 0 ]; then
    echo "error: module not found: $m   (try: $0 --list)" >&2; exit 1
  fi
  if [ "$n" -gt 1 ]; then
    echo "error: '$m' is ambiguous, matches:" >&2; printf '%s\n' "$match" | sed 's/^/  /' >&2; exit 1
  fi
  PATHS+=("$match")
done

git -C "$tmp" sparse-checkout init --cone >/dev/null 2>&1
git -C "$tmp" sparse-checkout set "${PATHS[@]}" >/dev/null 2>&1
git -C "$tmp" checkout >/dev/null 2>&1

mkdir -p "$DEST"
for p in "${PATHS[@]}"; do
  rel="${p#modules/}"                       # e.g. networking/aws-vpc
  mkdir -p "$DEST/$(dirname "$rel")"
  rm -rf "$DEST/$rel"
  cp -R "$tmp/$p" "$DEST/$rel"
done

echo "" >&2
echo "Vendored ${#PATHS[@]} module(s) into $DEST @ $REF:" >&2
for p in "${PATHS[@]}"; do
  rel="${p#modules/}"; name="$(basename "$rel")"
  printf '  module "%s" { source = "%s" }\n' "${name#aws-}" "$DEST/$rel" >&2
done
echo "" >&2
echo "Tip: commit the vendored copy, or add '$DEST' to .gitignore and re-run to update." >&2
