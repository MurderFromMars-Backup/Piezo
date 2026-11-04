#!/usr/bin/env bash
# Point Plasma's "On Battery" -> "Run script" at this file.
# Drops the laptop panel to ~60 Hz.
#
# Uncomment to override the defaults:
# export OUTPUT=eDP-1
# export BATTERY_HZ=60

exec "$(dirname "$(readlink -f "$0")")/refresh-rate.sh" battery
