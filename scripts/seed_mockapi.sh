#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# seed_mockapi.sh — reset and seed the LODBOD mockapi project
#
# Usage:
#   ./scripts/seed_mockapi.sh                   # uses default base URL
#   API_BASE_URL=https://...mockapi.io ./scripts/seed_mockapi.sh
#
# Prerequisites: curl, python3 (or jq as fallback)
#
# IMPORTANT — if the script fails during the "Clearing" step with 404
# errors, your mockapi data was created via the dashboard and has no
# auto-generated IDs. In that case:
#   1. Open https://mockapi.io → lodbod project → shipments → Data tab
#   2. Select all rows → Delete
#   3. Repeat for bids → Data tab → Select all → Delete
#   4. Re-run this script
# ──────────────────────────────────────────────────────────────
set -euo pipefail

BASE="${API_BASE_URL:-https://6af2103d42c6561ced38f683.mockapi.io}"

# ── helpers ──────────────────────────────────────────────────
list_ids() {
  python3 -c 'import json,sys; [print(item["id"]) for item in json.load(sys.stdin) if "id" in item]'
}

extract_id() {
  python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])'
}

post_json() {
  curl -fsS -X POST "$BASE/$1" \
    -H 'Content-Type: application/json' \
    -d "$2"
}

clear_resource() {
  local name="$1"
  echo "Clearing $name …"
  local ids
  ids=$(curl -fsS "$BASE/$name" | list_ids)
  if [ -z "$ids" ]; then
    echo "  No deletable records (no 'id' field). Delete manually in dashboard."
    return 0
  fi
  for id in $ids; do
    printf "  DELETE %s/%s … " "$name" "$id"
    curl -fsS -X DELETE "$BASE/$name/$id" > /dev/null && echo "ok" || echo "FAIL"
  done
}

# ── wipe existing data ──────────────────────────────────────
clear_resource bids
clear_resource shipments

# Verify empty
REMAIN=$(curl -fsS "$BASE/shipments" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')
if [ "$REMAIN" -gt 0 ]; then
  echo ""
  echo "⚠  $REMAIN shipments still remain (they lack IDs — created via dashboard)."
  echo "   Please delete them manually in the mockapi dashboard, then re-run this script."
  exit 1
fi

REMAIN_B=$(curl -fsS "$BASE/bids" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')
if [ "$REMAIN_B" -gt 0 ]; then
  echo ""
  echo "⚠  $REMAIN_B bids still remain (they lack IDs — created via dashboard)."
  echo "   Please delete them manually in the mockapi dashboard, then re-run this script."
  exit 1
fi

# ── seed shipments ──────────────────────────────────────────
echo ""
echo "Adding shipments …"

post_json shipments '{
  "reference":"LOD-1001",
  "shipperName":"Demo Shipper",
  "pickupCity":"Kathmandu",
  "pickupAddress":"Kalimati, Kathmandu",
  "destinationCity":"Pokhara",
  "destinationAddress":"Lakeside, Pokhara",
  "cargoDescription":"Steel pipes",
  "cargoCategory":"construction",
  "weight":10,
  "weightUnit":"tonnes",
  "vehicleType":"truck_10w",
  "pickupAt":"2027-01-20T08:00:00.000Z",
  "expectedFare":18000,
  "currency":"NPR",
  "status":"in_transit",
  "acceptedBidId":"",
  "assignedCarrier":"Everest Freight",
  "notes":"",
  "createdAt":"2026-11-02T10:00:00.000Z",
  "updatedAt":"2026-11-08T10:00:00.000Z"
}' > /dev/null
echo "  ✓ LOD-1001 (in_transit)"

SHIP_1002_JSON=$(post_json shipments '{
  "reference":"LOD-1002",
  "shipperName":"Demo Shipper",
  "pickupCity":"Birgunj",
  "pickupAddress":"Dry Port, Birgunj",
  "destinationCity":"Kathmandu",
  "destinationAddress":"Kalimati, Kathmandu",
  "cargoDescription":"Cement bags",
  "cargoCategory":"construction",
  "weight":12,
  "weightUnit":"tonnes",
  "vehicleType":"truck_10w",
  "pickupAt":"2027-01-21T08:00:00.000Z",
  "expectedFare":0,
  "currency":"NPR",
  "status":"awaiting_bids",
  "acceptedBidId":"",
  "assignedCarrier":"",
  "notes":"Handle with care",
  "createdAt":"2026-11-03T10:00:00.000Z",
  "updatedAt":"2026-11-03T10:00:00.000Z"
}')
SHIP_1002_ID=$(printf '%s' "$SHIP_1002_JSON" | extract_id)
echo "  ✓ LOD-1002 (awaiting_bids) — id=$SHIP_1002_ID"

post_json shipments '{
  "reference":"LOD-1003",
  "shipperName":"Demo Shipper",
  "pickupCity":"Butwal",
  "pickupAddress":"Traffic Chowk, Butwal",
  "destinationCity":"Narayanghat",
  "destinationAddress":"Pulchowk, Narayanghat",
  "cargoDescription":"Rice sacks",
  "cargoCategory":"agriculture",
  "weight":8,
  "weightUnit":"tonnes",
  "vehicleType":"truck_6w",
  "pickupAt":"2026-10-26T10:00:00.000Z",
  "expectedFare":12500,
  "currency":"NPR",
  "status":"delivered",
  "acceptedBidId":"",
  "assignedCarrier":"Terai Logistics",
  "notes":"",
  "createdAt":"2026-10-21T10:00:00.000Z",
  "updatedAt":"2026-10-27T10:00:00.000Z"
}' > /dev/null
echo "  ✓ LOD-1003 (delivered)"

post_json shipments '{
  "reference":"LOD-1004",
  "shipperName":"Demo Shipper",
  "pickupCity":"Kathmandu",
  "pickupAddress":"Balaju, Kathmandu",
  "destinationCity":"Biratnagar",
  "destinationAddress":"Main Road, Biratnagar",
  "cargoDescription":"Furniture",
  "cargoCategory":"household",
  "weight":4,
  "weightUnit":"tonnes",
  "vehicleType":"truck_6w",
  "pickupAt":"2027-01-22T08:00:00.000Z",
  "expectedFare":24000,
  "currency":"NPR",
  "status":"cancelled",
  "acceptedBidId":"",
  "assignedCarrier":"",
  "notes":"Cancelled by shipper",
  "createdAt":"2026-11-05T10:00:00.000Z",
  "updatedAt":"2026-11-06T10:00:00.000Z"
}' > /dev/null
echo "  ✓ LOD-1004 (cancelled)"

# ── seed bids (linked to LOD-1002) ──────────────────────────
echo ""
echo "Adding bids for LOD-1002 (shipmentId=$SHIP_1002_ID) …"

post_json bids "{
  \"shipmentId\":\"$SHIP_1002_ID\",
  \"carrierName\":\"Himalayan Cargo\",
  \"carrierRating\":4.6,
  \"carrierVerified\":true,
  \"fare\":32000,
  \"currency\":\"NPR\",
  \"etaDays\":2,
  \"estimatedDeliveryAt\":\"2027-01-23T18:00:00.000Z\",
  \"message\":\"Can pick up same day\",
  \"status\":\"pending\",
  \"createdAt\":\"2026-11-04T12:00:00.000Z\"
}" > /dev/null
echo "  ✓ Himalayan Cargo — NPR 32,000"

post_json bids "{
  \"shipmentId\":\"$SHIP_1002_ID\",
  \"carrierName\":\"Swift Transport\",
  \"carrierRating\":4.1,
  \"carrierVerified\":true,
  \"fare\":29500,
  \"currency\":\"NPR\",
  \"etaDays\":3,
  \"estimatedDeliveryAt\":\"2027-01-24T18:00:00.000Z\",
  \"message\":\"\",
  \"status\":\"pending\",
  \"createdAt\":\"2026-11-04T13:00:00.000Z\"
}" > /dev/null
echo "  ✓ Swift Transport — NPR 29,500"

# ── verify ──────────────────────────────────────────────────
echo ""
echo "════ Verification ════"
echo ""
echo "Shipments:"
curl -fsS "$BASE/shipments" | python3 -c '
import json, sys
data = json.load(sys.stdin)
for s in data:
    print("  id=%-4s ref=%-10s status=%-15s route=%s → %s" % (
        s.get("id","?"), s["reference"], s["status"],
        s["pickupCity"], s["destinationCity"]))
'

echo ""
echo "Bids (for shipmentId=$SHIP_1002_ID):"
curl -fsS "$BASE/bids?shipmentId=$SHIP_1002_ID" | python3 -c '
import json, sys
data = json.load(sys.stdin)
for b in data:
    print("  id=%-4s carrier=%-20s fare=NPR %s  eta=%sd  shipmentId=%s" % (
        b.get("id","?"), b["carrierName"], b["fare"], b["etaDays"], b["shipmentId"]))
'

echo ""
echo "✅ Seed complete. Use this to run the app against the API:"
echo "   flutter run --dart-define=API_BASE_URL=$BASE"
