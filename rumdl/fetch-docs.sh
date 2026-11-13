#!/bin/bash
set -euo pipefail

version="$(rumdl --version | awk '{print $2}')"
target=".rumdl-docs"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git -c advice.detachedHead=false clone --quiet --depth 1 --branch "v$version" --filter=blob:none --sparse \
  https://github.com/rvben/rumdl.git "$tmp/src"
git -C "$tmp/src" sparse-checkout set docs

rm -rf "$target"
cp -R "$tmp/src/docs" "$target"

echo "rumdl $version documentation: $(pwd)/$target"
