#!/usr/bin/env bash
set -euo pipefail

prefix="${PREFIX:-$HOME/.local/bin}"
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

mkdir -p "$prefix"
cp "$script_dir/ai-cli-paste" "$prefix/ai-cli-paste"
chmod +x "$prefix/ai-cli-paste"

printf 'installed: %s\n' "$prefix/ai-cli-paste"

case ":$PATH:" in
  *":$prefix:"*)
    ;;
  *)
    printf 'note: add this to your shell profile if needed:\n'
    printf '  export PATH="%s:$PATH"\n' "$prefix"
    ;;
esac
