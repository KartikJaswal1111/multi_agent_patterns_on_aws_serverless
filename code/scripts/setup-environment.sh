#!/usr/bin/env bash
# RECONSTRUCTED from docs/images/02-eventbridge-bus-lookup.png — see ../README.md for provenance.
#
# Resolves the workshop stack's region, account, event bus, and per-agent Lambda ARNs
# into shell variables that the other scripts in this folder assume are already exported.
set -euo pipefail

echo "$AWS_REGION"   # expected: us-west-2

export AWS_REGION=us-west-2
export AWS_ACCOUNT_ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export STACK_NAME=merged-multi-agent-workshop

EVENT_BUS_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='ChoreographyEventBusName'].OutputValue" \
  --output text)

PLANNER_FUNCTION_ARN="arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:${STACK_NAME}-planner-agent"
WEATHER_FUNCTION_ARN="arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:${STACK_NAME}-weather-agent"
FLIGHT_FUNCTION_ARN="arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:${STACK_NAME}-flight-manager-agent"

echo "Event Bus:        ${STACK_NAME}-multi-agent-bus"
echo "Planner Function:  $PLANNER_FUNCTION_ARN"
echo "Weather Function:  $WEATHER_FUNCTION_ARN"
echo "Flight Function:   $FLIGHT_FUNCTION_ARN"
