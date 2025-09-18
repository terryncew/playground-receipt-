#!/usr/bin/env bash
# Usage: ./olw.sh "pytest -q"  OR  ./olw.sh "echo hi"

set -euo pipefail
CMD="${1:-}"
if [ -z "$CMD" ]; then
  echo "usage: ./olw.sh \"<command to run>\"" >&2; exit 2
fi

mkdir -p docs
START_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Run the command, capture output
OUT=$(mktemp) ; ERR=$(mktemp) ; EXIT=0
{ bash -lc "$CMD"; } >"$OUT" 2>"$ERR" || EXIT=$?
END_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Summaries for the card (keep short)
snip () { head -c 400 "$1" | sed 's/"/\\"/g'; }
OUT_SNIP=$(snip "$OUT")
ERR_SNIP=$(snip "$ERR")

STATUS_TEXT=$([ $EXIT -eq 0 ] && echo "OK" || echo "ERROR")
TRAFFIC_LIGHT=$([ $EXIT -eq 0 ] && echo "green" || echo "red")
SO=$([ $EXIT -eq 0 ] && echo "ok" || echo "failed")

cat > docs/receipt.latest.json <<JSON
{
  "title": "Receipt",
  "status": "$STATUS_TEXT",
  "point": "Run terminal command",
  "because": [
    "cmd: $CMD",
    "start: $START_UTC",
    "end: $END_UTC"
  ],
  "but": "$ERR_SNIP",
  "so": "$SO",
  "output_preview": "$OUT_SNIP",
  "metrics": { "delta_scale": 0.000, "threshold": 0.030, "status": "$TRAFFIC_LIGHT" },
  "policy": { "use": "internal-demo", "share": "yes", "train": "no" }
}
JSON

rm -f "$OUT" "$ERR"
echo "Wrote docs/receipt.latest.json ($STATUS_TEXT). Commit & push to update the page."
