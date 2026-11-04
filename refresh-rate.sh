#!/usr/bin/env bash
# refresh-rate.sh <battery|ac>
# For use with Plasma's Power Management "Run script" hooks.
#   battery -> mode closest to BATTERY_HZ (default 60) at current resolution
#   ac      -> AC_HZ if set, otherwise the highest refresh rate available
#
# Optional environment overrides: OUTPUT=eDP-1  BATTERY_HZ=60  AC_HZ=165

set -u

BATTERY_HZ="${BATTERY_HZ:-60}"
AC_HZ="${AC_HZ:-}"
OUTPUT="${OUTPUT:-}"
STATE="${1:-}"

case "$STATE" in
    battery|ac) ;;
    *) echo "Usage: $0 <battery|ac>" >&2; exit 2 ;;
esac

strip_ansi() { sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g'; }

# Powerdevil can fire the hook right as the session settles; retry briefly.
info=""
for _ in 1 2 3 4 5; do
    info="$(kscreen-doctor -o 2>/dev/null | strip_ansi)"
    [[ -n "$info" ]] && break
    sleep 1
done
[[ -n "$info" ]] || { echo "kscreen-doctor returned nothing" >&2; exit 1; }

out="$OUTPUT"
if [[ -z "$out" ]]; then
    out="$(grep -oE 'Output: [0-9]+ (eDP|LVDS|DSI)[^ ]*' <<<"$info" | awk '{print $3}' | head -n1)"
fi
[[ -n "$out" ]] || { echo "No internal display found; set OUTPUT=..." >&2; exit 1; }

block="$(awk -v o="$out" '
    /^Output:/ { inblk = ($3 == o) }
    inblk { print }
' <<<"$info")"

cur="$(grep -oE '[^ ]+:[0-9]+x[0-9]+@[0-9.]+[^ ]*\*' <<<"$block" | head -n1)"
res="$(grep -oE '[0-9]+x[0-9]+' <<<"$cur" | head -n1)"
[[ -n "$res" ]] || { echo "Could not determine current mode for $out" >&2; exit 1; }

modes="$(grep -oE "[^ ]+:${res}@[0-9.]+" <<<"$block" \
         | sed -E "s/^([^:]+):${res}@([0-9.]+)$/\1 \2/")"

closest() {
    awk -v t="$1" '
        { d = ($2 - t); if (d < 0) d = -d
          if (best == "" || d < bd) { best = $1; br = $2; bd = d } }
        END { print best, br }' <<<"$modes"
}

if [[ "$STATE" == "battery" ]]; then
    read -r id rate < <(closest "$BATTERY_HZ")
elif [[ -n "$AC_HZ" ]]; then
    read -r id rate < <(closest "$AC_HZ")
else
    read -r id rate < <(sort -k2,2 -nr <<<"$modes" | head -n1)
fi

[[ -n "${id:-}" ]] || { echo "No matching mode found" >&2; exit 1; }

# Already on that mode? Nothing to do.
if grep -qE "(^| )${id}:${res}@[0-9.]+[^ ]*\*" <<<"$block"; then
    exit 0
fi

echo "Setting $out to ${res}@${rate} ($STATE)"
exec kscreen-doctor "output.${out}.mode.${id}"
