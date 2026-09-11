#!/usr/bin/env bash
# RECONSTRUCTED from docs/images/07-orchestration-state-machine-definition.png,
# docs/images/08-step-functions-state-machine-created.png, and
# docs/images/09-step-functions-execution-graph-running.png — see ../README.md.
#
# The `sed` substitution block and its final echo below are close to a literal transcript.
# The create-state-machine / start-execution calls are inferred — they weren't directly
# visible on screen, only their result (the deployed state machine and a running execution).
set -euo pipefail

export AWS_REGION=us-west-2
export AWS_ACCOUNT_ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export STACK_NAME=orchestration-multi-agent-workshop

ORCH_PLANNER_ARN="arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:${STACK_NAME}-orch-planner-agent"
ORCH_WEATHER_ARN="arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:${STACK_NAME}-orch-weather-agent"
ORCH_FLIGHT_ARN="arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:${STACK_NAME}-orch-flight-manager-agent"
ACTIVITY_ARN="arn:aws:states:${AWS_REGION}:${AWS_ACCOUNT_ID}:activity:${STACK_NAME}-human-review-activity"
EXECUTION_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${STACK_NAME}-stepfunctions-execution-role"

echo "Planner Function: $ORCH_PLANNER_ARN"
echo "Weather Function:  $ORCH_WEATHER_ARN"
echo "Flight Function:   $ORCH_FLIGHT_ARN"
echo "Activity ARN:      $ACTIVITY_ARN"
echo "Execution Role:    $EXECUTION_ROLE_ARN"

# Replace placeholders with the actual ARNs resolved above
sed -i.bak "s|\${OrchPlannerFunctionArn}|$ORCH_PLANNER_ARN|g" travel-booking-orchestration.asl.json
sed -i.bak "s|\${OrchWeatherFunctionArn}|$ORCH_WEATHER_ARN|g" travel-booking-orchestration.asl.json
sed -i.bak "s|\${OrchFlightFunctionArn}|$ORCH_FLIGHT_ARN|g" travel-booking-orchestration.asl.json
sed -i.bak "s|\${HumanReviewActivityArn}|$ACTIVITY_ARN|g" travel-booking-orchestration.asl.json

echo "✅ ASL definition prepared with actual ARNs"

aws stepfunctions create-state-machine \
  --name travel-booking-orchestration \
  --definition file://travel-booking-orchestration.asl.json \
  --role-arn "$EXECUTION_ROLE_ARN" \
  --type STANDARD \
  --region "$AWS_REGION"

aws stepfunctions start-execution \
  --state-machine-arn "arn:aws:states:${AWS_REGION}:${AWS_ACCOUNT_ID}:stateMachine:travel-booking-orchestration" \
  --name "high-risk-test-$(date +%s)" \
  --input file://high-risk-booking.json \
  --region "$AWS_REGION"
