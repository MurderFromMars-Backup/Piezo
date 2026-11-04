#!/usr/bin/env bash
# Point Plasma's "On AC Power" -> "Run script" at this file.
# Puts the laptop panel back to its highest refresh rate.
#
# Uncomment to override the defaults:
# export OUTPUT=eDP-1
# export AC_HZ=120

exec "$(dirname "$(readlink -f "$0")")/refresh-rate.sh" ac
