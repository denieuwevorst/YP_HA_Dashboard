#!/bin/bash
# Dagplanning — haalt evenementen + tijdschema + resources op voor vandaag
# Configuratie wordt geladen uit config.json (zelfde map als dit script)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/config.json"

if [ ! -f "$CONFIG" ]; then
  echo "ERROR: config.json niet gevonden in $SCRIPT_DIR"
  exit 1
fi

API_KEY=$(jq -r '.api_key' "$CONFIG")
BASE=$(jq -r '.base_url' "$CONFIG")
OUTPUT_DIR=$(jq -r '.output_dir' "$CONFIG")
OUTPUT_FILE="${OUTPUT_DIR}/dagplanning.json"

mapfile -t LOCATIES < <(jq -r '.locaties[]' "$CONFIG")

TODAY=$(date +%d-%m-%Y)

ALL_EVENTS=$(curl -s "${BASE}/events/date:${TODAY}?api_key=${API_KEY}" | jq '
  [.data[] | select(.status.name != "Geannuleerd")]
')

RESULT="[]"

for LOCATIE in "${LOCATIES[@]}"; do
  ZAAL_EVENTS=$(echo "$ALL_EVENTS" | jq --arg loc "$LOCATIE" '
    [.[] | select(.locations[]?.name == $loc)]
  ')

  EVENT_COUNT=$(echo "$ZAAL_EVENTS" | jq 'length')
  [ "$EVENT_COUNT" -eq 0 ] && continue

  for i in $(seq 0 $((EVENT_COUNT - 1))); do
    EVENT=$(echo "$ZAAL_EVENTS" | jq ".[$i]")
    EVENT_ID=$(echo "$EVENT" | jq -r '.id')

    SCHEDULE=$(curl -s "${BASE}/event/${EVENT_ID}/schedule?api_key=${API_KEY}" | jq '.entries')

    RESOURCES=$(curl -s "${BASE}/event/${EVENT_ID}/resourcebookings?api_key=${API_KEY}" | jq '
      [
        (.[] | if .children then .children[] else . end) |
        select(._type == "resourcebooking") |
        {
          naam: .resource.name,
          type: .resource.resourcetype,
          groep: .resourcegroup,
          rol: (.role // null),
          start: .start,
          eind: .end
        }
      ] | sort_by(.groep, .naam)
    ')

    EVENT_WITH_META=$(echo "$EVENT" | jq \
      --arg zaal "$LOCATIE" \
      --argjson schedule "$SCHEDULE" \
      --argjson res "$RESOURCES" \
      '. + {zaal: $zaal, schedule: $schedule, resources: $res}')

    RESULT=$(echo "$RESULT" | jq --argjson ev "$EVENT_WITH_META" '. + [$ev]')
  done
done

echo "$RESULT" | jq 'sort_by(.zaal, .starttime)' > "$OUTPUT_FILE"
echo "$(date): $(jq length $OUTPUT_FILE) events opgeslagen in $OUTPUT_FILE"
