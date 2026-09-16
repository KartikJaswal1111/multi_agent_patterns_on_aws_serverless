#!/usr/bin/env bash
# RECONSTRUCTED from docs/images/11-hotel-agent-lambda-code-deployed.png and
# docs/images/12-hotel-agent-invocation-result.png - see ../../README.md.
#
# The function name, runtime, logging config, and the final `aws lambda invoke` call
# (including its exact payload and flags) are close to a literal transcript. The --role
# ARN pattern is inferred - the create-function command scrolled past on screen, only its
# tail (LoggingConfig) and success message were visible.
#
# The packaging step below (pip install + zip) is NOT from a screenshot - it's added
# because lambda_function.py imports `strands`, a third-party package not present in the
# default Lambda runtime. A bare `zip -r hotel-agent.zip lambda_function.py` deploys
# successfully but fails at invoke time with ModuleNotFoundError: No module named 'strands'.
# The workshop may have used a pre-built Lambda layer instead of bundling dependencies this
# way - there's no screenshot evidence either way - but this is the correct, self-contained
# way to make the real code actually runnable.
set -euo pipefail

export AWS_REGION=us-west-2
export AWS_ACCOUNT_ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export STACK_NAME=merged-multi-agent-workshop

rm -rf build hotel-agent.zip
mkdir build
cp lambda_function.py build/
pip install -r requirements.txt -t build/ --quiet
(cd build && zip -r ../hotel-agent.zip .)

aws lambda create-function \
  --function-name "${STACK_NAME}-hotel-agent" \
  --runtime python3.13 \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://hotel-agent.zip \
  --role "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${STACK_NAME}-lambda-execution-role" \
  --region "$AWS_REGION" \
  --logging-config LogFormat=Text,LogGroup=/aws/lambda/${STACK_NAME}-hotel-agent

echo "✅ Hotel Agent deployed: arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:${STACK_NAME}-hotel-agent"

# Subscribe the new function to FinalBookingCompleted events on the existing bus so it
# reacts to real completed bookings without touching any other agent (see docs/04).
aws events put-targets \
  --event-bus-name "${STACK_NAME}-multi-agent-bus" \
  --rule "FinalBookingCompleted" \
  --targets "Id"="hotel-agent","Arn"="arn:aws:lambda:${AWS_REGION}:${AWS_ACCOUNT_ID}:function:${STACK_NAME}-hotel-agent" \
  --region "$AWS_REGION"

# Direct invocation test - this exact call and payload are what docs/images/12 shows
aws lambda invoke \
  --function-name "${STACK_NAME}-hotel-agent" \
  --payload '{"detail":{"booking_id":"hotel-test-001","destination":"Miami","budget":1000}}' \
  --cli-binary-format raw-in-base64-out \
  --region "$AWS_REGION" \
  /dev/stdout
