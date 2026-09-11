# Multi-Agent Patterns on AWS Serverless

<img src="docs/images/badge-building-agentic-ai-aws-serverless.png" width="150" align="right" alt="Proficient badge — Building Agentic AI with AWS Serverless">

Hands-on notes and architecture write-up from building an event-driven, multi-agent travel-booking
system on AWS — comparing **choreography** (EventBridge) and **orchestration** (Step Functions) as
coordination strategies for asynchronous AI agents, with human-in-the-loop approval and
distributed observability layered on top.

![AWS Serverless](https://img.shields.io/badge/AWS-Serverless-FF9900?logo=amazonaws&logoColor=white)
![Status: Reference Architecture](https://img.shields.io/badge/Status-Reference%20Architecture-informational)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

<br clear="right">

## Contents

- [How to explore this repo](#how-to-explore-this-repo)
- [The problem](#the-problem)
- [Architecture patterns](#architecture-patterns)
- [What I built](#what-i-built)
- [Code](#code)
- [Key takeaways](#key-takeaways)
- [What I'd change for a production system](#what-id-change-for-a-production-system)
- [Tech stack](#tech-stack)
- [Proof of work](#proof-of-work)
- [Certification](#certification)
- [Disclaimer](#disclaimer)
- [License](#license)

## How to explore this repo

| If you're here to... | Start with |
|---|---|
| Get the 2-minute version | This README, top to bottom |
| Evaluate the architecture decision | [`architecture/HLD.md`](architecture/HLD.md) — requirements, decision matrix, recommendation |
| See the technical depth, module by module | [`docs/`](docs/) — five walkthroughs, each with real screenshots |
| Check which AWS service does what | [`aws-services/`](aws-services/) — official icons mapped to their role |
| Look at actual code | [`code/`](code/) — read [`code/README.md`](code/README.md) first; most of it is reconstructed, except the hotel-agent Lambda, which is the actual verbatim source |

## The problem

Synchronous agent calls are easy to prototype and fall apart in production. The moment an agent
needs to think for a while, call a slow external API, run a multi-step reasoning chain, or wait on
a human decision, a request/response call either times out or burns serverless compute sitting
idle. Real systems need agents that can run independently, communicate through events, and pick
back up after a delay — without one slow agent blocking the rest of the system.

This project explores two ways to solve that on AWS, using a travel-booking scenario as the
concrete example: a request comes in, a planner agent breaks it down, a weather agent and a
flight-search agent do their own work in parallel, and — for high-risk bookings — a human has to
sign off before anything is finalized.

## Architecture patterns

| | Choreography | Orchestration |
|---|---|---|
| **Coordinator** | None — agents react to events on an event bus | A central state machine drives the sequence |
| **AWS service** | EventBridge | Step Functions |
| **Coupling** | Loose — agents don't know about each other, only the events they care about | Tighter — the state machine knows every step and every agent |
| **Best for** | Extensibility — adding a new agent means subscribing it to events, zero changes to existing agents | Control — explicit sequencing, retries, branching, and an auditable execution history |
| **Trade-off** | Harder to see the "whole picture" of a workflow without tracing events end-to-end | Adding a new step means editing the state machine definition |

Full write-ups with diagrams: [`architecture/choreography.md`](architecture/choreography.md) ·
[`architecture/orchestration.md`](architecture/orchestration.md)

For the requirements-driven comparison of both options — NFRs, a decision matrix, and a
recommendation — see the [**High-Level Design**](architecture/HLD.md).

## What I built

| Module | What it covers |
|---|---|
| [01 — Choreography Pattern](docs/01-choreography-pattern.md) | Event-driven agents coordinating through EventBridge, correlated by a shared booking ID |
| [02 — Orchestration Pattern](docs/02-orchestration-pattern.md) | A Step Functions state machine driving planner, weather, and flight agents through explicit sequencing and parallel branches |
| [03 — Human-in-the-Loop Approval](docs/03-human-in-the-loop.md) | Routing high-risk bookings to a manual review step before the workflow can complete |
| [04 — Extending the System](docs/04-extending-the-system.md) | Adding a new Hotel Recommendation agent to the choreography pattern without touching any existing agent |
| [05 — Observability](docs/05-observability.md) | Tracing a single booking's full event history across agents using CloudWatch Logs Insights |

## Code

[`code/`](code/) has the event payloads, the Step Functions ASL definition, and the hotel-agent
Lambda. Most of it is reconstructed from what's directly visible in the screenshots below, since I
couldn't retrieve the original workshop source — except the hotel-agent Lambda itself, which is the
actual verbatim code (MIT-0 licensed by AWS). See [`code/README.md`](code/README.md) for exactly
what's evidenced, verbatim, or illustrative in each file.

## Key takeaways

1. **Serverless agents scale by default.** Running each agent on Lambda removes infrastructure
   management entirely and means you only pay for actual execution time.
2. **Choreography optimizes for change.** Because agents only know about the events they
   subscribe to, adding a new agent (see [module 04](docs/04-extending-the-system.md)) required no
   changes to any existing agent's code.
3. **Orchestration optimizes for guarantees.** When a workflow needs strict ordering, retries, and
   a provable audit trail, a central state machine is worth the tighter coupling it introduces.
4. **Not every decision belongs to a model.** Routing high-risk bookings to a human reviewer
   before continuing the workflow is a deliberate reliability and compliance control, not a
   fallback for a weak agent.
5. **Distributed systems are only debuggable if you design for it.** Correlating every event by a
   shared booking ID made it possible to reconstruct a full request's lifecycle after the fact in
   CloudWatch Logs Insights — see [module 05](docs/05-observability.md).

## What I'd change for a production system

- Make every agent handler idempotent against `bookingID`. EventBridge and Step Functions both
  guarantee at-least-once delivery, so a retried event or task should never double-book or
  double-charge a traveler — nothing here currently protects against that.
- Version the event schemas (`TravelRequestSubmitted`, `FlightSearchCompleted`, etc.) so agents can
  evolve independently without breaking consumers — choreography's loose coupling only holds if the
  event contracts are stable.
- Move the human-approval SLA out of a fixed timeout and into a monitored queue with alerting, so a
  stalled review doesn't silently strand a booking.
- Add tracing headers through to X-Ray by default instead of enabling it per-resource, since the
  main debugging cost in this architecture is reconstructing a request's path across services.

## Tech stack

AWS Lambda · Amazon EventBridge · AWS Step Functions · Amazon SQS · Amazon SNS · Amazon CloudWatch ·
AWS X-Ray · AWS IAM · Python

See [`aws-services/`](aws-services/) for how each service maps to its role in this
architecture, with the official AWS service icons.

## Proof of work

Screenshots of the actual deployed system (CloudWatch logs, Step Functions executions, Lambda
invocations) are embedded throughout the module docs in `docs/`, not just linked at the end — each
one sits next to the explanation of what it's showing.

## Certification

See [`CERTIFICATION.md`](CERTIFICATION.md).

## Disclaimer

This is an independent write-up of my own hands-on work completing a public AWS Workshop Studio
lab ("Building Agentic AI architectures with AWS Serverless"). All explanations, diagrams, and
opinions are my own. This is not an official AWS resource and is not affiliated with or endorsed
by Amazon Web Services.

## License

[MIT](LICENSE)
