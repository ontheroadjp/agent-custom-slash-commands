#!/bin/bash
set -euo pipefail

payload=$(cat)
transcript_path=$(echo "$payload" | jq -r '.transcript_path // empty')
session_id=$(echo "$payload" | jq -r '.session_id // "unknown"')

[ -z "$transcript_path" ] || [ ! -f "$transcript_path" ] && exit 0

totals=$(jq -sc '
  [.[] | select(.type == "assistant" and .message.usage != null) | .message.usage] |
  {
    input:        (map(.input_tokens                // 0) | add // 0),
    output:       (map(.output_tokens               // 0) | add // 0),
    cache_create: (map(.cache_creation_input_tokens // 0) | add // 0),
    cache_read:   (map(.cache_read_input_tokens     // 0) | add // 0)
  }
' "$transcript_path")

input=$(echo "$totals"        | jq -r '.input')
output=$(echo "$totals"       | jq -r '.output')
cache_create=$(echo "$totals" | jq -r '.cache_create')
cache_read=$(echo "$totals"   | jq -r '.cache_read')
total=$((input + output + cache_create))

log_file="$HOME/.claude/token-usage.log"
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

printf '[%s] session=%-36s  input=%6d  output=%6d  cache_read=%7d  cache_create=%6d  total=%7d\n' \
  "$timestamp" "$session_id" "$input" "$output" "$cache_read" "$cache_create" "$total" \
  >> "$log_file"
