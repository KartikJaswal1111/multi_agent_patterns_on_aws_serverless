# Code — Mostly Reconstructed

**Read this before trusting anything in this folder.**

I don't have the original source files from the workshop. The workshop link itself renders as a
JS application behind a per-participant login and isn't fetchable from outside a live session, and
I couldn't find a public GitHub repo backing this specific workshop (it's branded "BeSA," not an
official `aws-samples` workshop, so there's no public mirror to pull from).

Most of what follows is **my own reconstruction**, rebuilt from what's directly visible across the
13 proof-of-work screenshots embedded in [`../docs/`](../docs) — terminal commands, file contents
partially shown in the VS Code editor, and CLI input/output. Where a screenshot shows something
close to verbatim (a command, a literal value, a JSON field), I kept it exact. Where a screenshot
only implies a shape or a step wasn't visible at all, I filled the gap with a clearly-commented,
illustrative placeholder — and the table below says which is which.

**One exception:** [`agents/hotel-agent/lambda_function.py`](agents/hotel-agent/lambda_function.py)
is the **actual verbatim source**, recovered directly from the workshop environment — not a
reconstruction. It carries AWS's own **MIT-0 (MIT No Attribution)** license header, which is what
makes redistributing it here legitimate; that header is kept intact and must stay that way. It's
also the reason the rest of this repo's tech-stack references don't yet mention Amazon Bedrock,
the Strands Agents SDK, or Amazon S3 session storage, all of which this file actually uses — those
were only confirmed for this one agent, not the others, so they haven't been generalized into the
architecture docs yet.

## Provenance

| File | Based on | Confidence |
|---|---|---|
| [`scripts/setup-environment.sh`](scripts/setup-environment.sh) | [Screenshot 02](../docs/images/02-eventbridge-bus-lookup.png) — near-exact terminal transcript (region, account/stack env vars, bus-name lookup, echoed function ARNs) | High — close to a literal transcript |
| [`choreography/events/travel-request-event.json`](choreography/events/travel-request-event.json) | [Screenshot 03](../docs/images/03-travel-request-event-published.png) — event source/detail-type and echoed booking ID, route, and dates are literal; surrounding fields (travelers, preferences) are illustrative | Mixed — literal core, invented shape around it |
| [`choreography/publish-travel-request.sh`](choreography/publish-travel-request.sh) | Same screenshot — `put-events` call structure | Mixed |
| [`orchestration/travel-booking-orchestration.asl.json`](orchestration/travel-booking-orchestration.asl.json) | [Screenshot 07](../docs/images/07-orchestration-state-machine-definition.png) (`Comment`, `StartAt`, and the first state are literal) + the state names and transitions visible in the execution graphs ([Screenshot 09](../docs/images/09-step-functions-execution-graph-running.png), [Screenshot 10](../docs/images/10-step-functions-execution-graph-completed.png)) | Mixed — real state names and topology, reconstructed `Parameters`/`ResultPath`/`Catch` detail |
| [`orchestration/high-risk-booking.json`](orchestration/high-risk-booking.json) | Field names (`within_budget`, `flights_available`) are literal, taken from the step-output log visible in [Screenshot 10](../docs/images/10-step-functions-execution-graph-completed.png); values are illustrative | Mixed |
| [`orchestration/deploy-state-machine.sh`](orchestration/deploy-state-machine.sh) | [Screenshot 07](../docs/images/07-orchestration-state-machine-definition.png) — the `sed` placeholder substitution and its exact success message are literal; the `create-state-machine`/`start-execution` calls are inferred (not directly visible on screen) | Mixed |
| [`agents/hotel-agent/lambda_function.py`](agents/hotel-agent/lambda_function.py) | Recovered directly from the workshop environment | **Verbatim source** — not reconstructed |
| [`agents/hotel-agent/deploy-and-test.sh`](agents/hotel-agent/deploy-and-test.sh) | [Screenshot 11](../docs/images/11-hotel-agent-lambda-code-deployed.png) & [Screenshot 12](../docs/images/12-hotel-agent-invocation-result.png) for function name, runtime, logging config, and the exact `aws lambda invoke` call. The `pip install` + packaging step is **not** from a screenshot — it was added after the real `lambda_function.py` landed, since the file imports `strands` and a bare zip would fail at invoke time with `ModuleNotFoundError`. | Mixed — literal CLI calls, added packaging step for correctness |
| [`agents/hotel-agent/requirements.txt`](agents/hotel-agent/requirements.txt) | Not from a screenshot — added so `deploy-and-test.sh` actually works against the real `lambda_function.py`'s imports | Inferred — package name is correct, exact version unconfirmed |

## What's deliberately not here

No IAM policy documents, no CloudFormation/SAM template that provisioned the stack, and no source
for the planner/weather/flight-search agents beyond what the diagrams already describe — none of
that was visible in any screenshot, so reconstructing it would be pure invention rather than a
grounded best-effort rebuild. If you still have access to the original Workshop Studio environment
or exported files, replacing anything here with the real source is a straightforward drop-in.
