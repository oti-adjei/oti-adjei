#!/usr/bin/env bash
# Build light + dark twins of every source SVG.
#
# Each source in build/src/ carries neutral CSS custom properties and a
# /*@THEME@*/ marker inside its <style> block. This script swaps that marker
# for a concrete palette and writes the result to assets/ (light) and
# assets/dark/ (dark). GitHub picks between them with <picture> media queries,
# so prefers-color-scheme inside the SVG is never relied on.
#
# Sources beginning with "_" are templates, not assets. The section dividers
# (s01..sNN) are generated from _section.svg and the $sections list below, so
# adding or reordering a section means editing one line here, not writing
# another near-identical file.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root/build/src"
out="$root/assets"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

light=':root { --bone:#0A0A0A; --muted:#6E6E6E; --dim:#9A9A9A; --rule:#D8D8D8; --accent:#0A0A0A; --ghost:#EBEBEB; --node-bg:#FFFFFF; --core-bg:#F4F4F4; --ink:#0A0A0A; --paper:#FFFFFF; }'
dark=':root { --bone:#EDEDED; --muted:#8B949E; --dim:#5E656D; --rule:#30363D; --accent:#EDEDED; --ghost:#1B1F24; --node-bg:#0D1117; --core-bg:#161B22; --ink:#EDEDED; --paper:#0D1117; }'

# One entry per section divider, in page order: "LABEL|path-slug"
sections=(
  "WHOAMI|whoami"
  "SELECTED WORK|work"
  "THE ROUTE|route"
  "STACK|stack"
  "TELEMETRY|telemetry"
)

# One entry per project card: "NUM|TITLE|line one|line two|TECH META"
# Each becomes its own image so the README can wrap it in a link.
cards=(
  "01|SIGNAL|Esports news and tournament platform, in active|development.|TYPESCRIPT &#183; WEB &#183; IN DEVELOPMENT"
  "02|NAGYIQUE BOUTIQUE|Boutique e-commerce: Astro storefront, admin portal|and a TypeScript API on Workers, with Stripe.|ASTRO &#183; TYPESCRIPT &#183; STRIPE &#183; WORKERS &#183; SENVON"
  "03|ZOOK|Tiny deploy controller for Docker Compose and native|systemd apps. Ships through its own Homebrew tap.|GO &#183; DOCKER &#183; SYSTEMD &#183; HOMEBREW"
  "04|MOTE|Deterministic animated background fields &#8212; designed|shape sets, not generic particles.|TYPESCRIPT &#183; CANVAS &#183; OPEN SOURCE"
  "05|WOLEVO|Flutter client for a shop-and-ship service delivering|from US stores to Ghana and Nigeria.|FLUTTER &#183; DART &#183; MOBILE"
  "06|GULLIVERS TRAVEL HOTEL|Hotel site with amenities, services and booking.|Shipped once, then rebuilt in React on Cloudflare.|REACT &#183; CLOUDFLARE PAGES &#183; D1 &#183; SENVON"
)

mkdir -p "$out/dark"

# Expand the divider template into $tmp, one file per section.
n=0
for entry in "${sections[@]}"; do
  n=$((n + 1))
  label="${entry%%|*}"
  slug="${entry##*|}"
  num="$(printf '%02d' "$n")"
  # The rule starts after the label: 128px left margin, ~14.4px per character
  # at font-size 14 with 6px letter-spacing, then a 36px gap.
  x1=$(awk -v l="${#label}" 'BEGIN { printf "%d", 128 + l * 14.4 + 36 }')
  sed -e "s/@NUM@/$num/g" \
      -e "s/@LABEL@/$label/g" \
      -e "s|@PATH@|~/$num-$slug|g" \
      -e "s/@X1@/$x1/g" \
      "$src/_section.svg" > "$tmp/s$num.svg"
done

# Expand the card template into $tmp, one file per project.
for entry in "${cards[@]}"; do
  IFS='|' read -r num title c1 c2 meta <<< "$entry"
  # & is "the matched text" to sed, and these strings carry HTML entities
  title="${title//&/\\&}"; c1="${c1//&/\\&}"; c2="${c2//&/\\&}"; meta="${meta//&/\\&}"
  sed -e "s/@NUM@/$num/g" \
      -e "s/@TITLE@/$title/g" \
      -e "s|@C1@|$c1|g" \
      -e "s|@C2@|$c2|g" \
      -e "s|@META@|$meta|g" \
      "$src/_card.svg" > "$tmp/card$num.svg"
done

count=0
for f in "$src"/*.svg "$tmp"/*.svg; do
  name="$(basename "$f")"
  case "$name" in _*) continue ;; esac
  # The light twin also carries the dark palette behind a prefers-color-scheme
  # query. GitHub's <picture> switch picks a file from the browser's colour
  # scheme, which can resolve light even when the site theme is dark -- when
  # that happens this file is served into a dark page, and the query saves it.
  awk -v repl="$light" -v darkrepl="$dark" '
    { if ($0 ~ /\/\*@THEME@\*\//) {
        print "    " repl
        print "    @media (prefers-color-scheme: dark) { " darkrepl " }"
      } else print }' "$f" > "$out/$name"
  awk -v repl="$dark" '{ if ($0 ~ /\/\*@THEME@\*\//) print "    " repl; else print }' "$f" > "$out/dark/$name"
  count=$((count + 1))
done

echo "built $count asset(s) -> $out and $out/dark (${#sections[@]} divider(s), ${#cards[@]} card(s))"
