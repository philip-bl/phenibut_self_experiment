#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

{ head -1 daily_stats.csv; awk 'NR != 1' daily_stats.csv | sort; } > sorted_daily_stats.csv
awk -f check_blind.awk sorted_daily_stats.csv
