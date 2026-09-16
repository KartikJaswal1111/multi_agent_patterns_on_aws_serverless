#!/usr/bin/env bash
# RECONSTRUCTED from docs/images/03-travel-request-event-published.png - see ../README.md.
#
# Publishes a TravelRequestSubmitted event onto the choreography event bus, kicking off
# the workflow described in ../../docs/01-choreography-pattern.md.
#
# Requires: source ../scripts/setup-environment.sh first (for $EVENT_BUS_NAME).
set -euo pipefail

aws events put-events --entries '[
  {
    "Source": "workshop.travel-request",
    "DetailType": "TravelRequestSubmitted",
    "EventBusName": "'"$EVENT_BUS_NAME"'",
    "Detail": "{\"bookingID\":\"high-risk-test-456\",\"origin\":\"LAX\",\"destination\":\"Miami\",\"startDate\":\"2026-03-20\",\"endDate\":\"2026-03-23\",\"travelers\":1,\"budget\":1000}"
  }
]'

echo "✅ Travel request event published!"
echo "📋 Booking ID: high-risk-test-456"
echo "✈️  Route: LAX → Miami"
echo "📅 Dates: March 20-23, 2026"
