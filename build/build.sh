#!/usr/bin/env bash
# Build light + dark twins of every source SVG.
#
# Each source in build/src/ carries neutral CSS custom properties and a
# /*@THEME@*/ marker inside its <style> block. This script swaps that marker
# for a concrete palette and writes the result to assets/ (light) and
# assets/dark/ (dark). GitHub picks between them with <picture> media queries,
# so prefers-color-scheme inside the SVG is never relied on.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root/build/src"
out="$root/assets"

light=':root { --bone:#0A0A0A; --muted:#6E6E6E; --dim:#9A9A9A; --rule:#D8D8D8; --accent:#0A0A0A; --ghost:#EBEBEB; --node-bg:#FFFFFF; --core-bg:#F4F4F4; --ink:#0A0A0A; --paper:#FFFFFF; }'
dark=':root { --bone:#EDEDED; --muted:#8B949E; --dim:#5E656D; --rule:#30363D; --accent:#EDEDED; --ghost:#1B1F24; --node-bg:#0D1117; --core-bg:#161B22; --ink:#EDEDED; --paper:#0D1117; }'

mkdir -p "$out/dark"

count=0
for f in "$src"/*.svg; do
  name="$(basename "$f")"
  awk -v repl="$light" '{ if ($0 ~ /\/\*@THEME@\*\//) print "    " repl; else print }' "$f" > "$out/$name"
  awk -v repl="$dark"  '{ if ($0 ~ /\/\*@THEME@\*\//) print "    " repl; else print }' "$f" > "$out/dark/$name"
  count=$((count + 1))
done

echo "built $count source(s) -> $out and $out/dark"
