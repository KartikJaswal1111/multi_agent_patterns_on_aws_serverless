# AWS Services Used

Every service below is mapped to the specific role it plays in this architecture - not just listed,
but tied back to the module that shows it running. For the full topology diagrams, see
[`../architecture/`](../architecture); this page is the service-level index into them.

## Services at a glance

| Icon | Service | Category | Role in this project | Where it's covered |
|:---:|---|---|---|---|
| <img src="icons/lambda.png" width="48" alt="AWS Lambda"> | **AWS Lambda** | Compute | Runs every agent - planner, weather, flight-search, and hotel - as an independent function. The one piece of compute shared by both coordination patterns. | [Module 01](../docs/01-choreography-pattern.md) · [02](../docs/02-orchestration-pattern.md) · [04](../docs/04-extending-the-system.md) |
| <img src="icons/eventbridge.png" width="48" alt="Amazon EventBridge"> | **Amazon EventBridge** | Application Integration | The central event bus for the **choreography** pattern - every agent publishes and subscribes here, with no agent calling another directly. | [Module 01](../docs/01-choreography-pattern.md) · [`architecture/choreography.md`](../architecture/choreography.md) |
| <img src="icons/step-functions.png" width="48" alt="AWS Step Functions"> | **AWS Step Functions** | Application Integration | The central state machine for the **orchestration** pattern - owns sequencing, the parallel weather/flight branch, retries, and the human-approval wait state. | [Module 02](../docs/02-orchestration-pattern.md) · [`architecture/orchestration.md`](../architecture/orchestration.md) |
| <img src="icons/sqs.png" width="48" alt="Amazon SQS"> | **Amazon SQS** | Application Integration | Backs the human-review queue in the **choreography** pattern only - holds a flagged booking durably until a reviewer responds. Orchestration deliberately skips SQS in favor of a Step Functions Activity + task token (see below). | [Module 03](../docs/03-human-in-the-loop.md) |
| <img src="icons/sns.png" width="48" alt="Amazon SNS"> | **Amazon SNS** | Application Integration | Delivers the final outbound notification (e.g. the hotel-recommendation email) once an agent completes its work. | [Module 04](../docs/04-extending-the-system.md) |
| <img src="icons/cloudwatch.png" width="48" alt="Amazon CloudWatch"> | **Amazon CloudWatch** | Management & Governance | Logs + Logs Insights for every agent; the `bookingID`-correlated queries that reconstruct a request's full lifecycle after the fact. | [Module 05](../docs/05-observability.md) |
| <img src="icons/xray.png" width="48" alt="AWS X-Ray"> | **AWS X-Ray** | Developer Tools | Distributed tracing across EventBridge, Step Functions, and Lambda - the cross-service half of observability that logs alone can't give you. | [Module 05](../docs/05-observability.md) |
| <img src="icons/iam.png" width="48" alt="AWS IAM"> | **AWS IAM** | Security, Identity & Compliance | One least-privilege execution role per Lambda function - no agent holds permissions it doesn't need, and no credentials are shared between agents. | [`architecture/HLD.md` §7.4](../architecture/HLD.md#74-security) |

## How the services connect - choreography

<table>
<tr>
<td align="center"><img src="icons/lambda.png" width="40"><br><sub>Agents</sub></td>
<td align="center">→</td>
<td align="center"><img src="icons/eventbridge.png" width="40"><br><sub>Event Bus</sub></td>
<td align="center">→</td>
<td align="center"><img src="icons/sqs.png" width="40"><br><sub>Review Queue</sub></td>
<td align="center">→</td>
<td align="center"><img src="icons/sns.png" width="40"><br><sub>Notification</sub></td>
</tr>
</table>

Every arrow above is really bidirectional through the Event Bus - agents publish back to it as often
as they consume from it. See [`architecture/choreography.md`](../architecture/choreography.md) for
the actual hub-and-spoke diagram; this row is a service-level summary, not the topology.

## How the services connect - orchestration

<table>
<tr>
<td align="center"><img src="icons/step-functions.png" width="40"><br><sub>State Machine</sub></td>
<td align="center">→</td>
<td align="center"><img src="icons/lambda.png" width="40"><br><sub>Agents</sub></td>
<td align="center">→</td>
<td align="center"><img src="icons/step-functions.png" width="40"><br><sub>Activity +<br>Task Token</sub></td>
<td align="center">→</td>
<td align="center"><img src="icons/sns.png" width="40"><br><sub>Notification</sub></td>
</tr>
</table>

Here Step Functions stays in control of the sequence throughout - it invokes each agent as a `Task`
state rather than the agents reacting to events independently, and pauses for human review through
its own Activity + task-token mechanism rather than an SQS queue (the ASL definition's own `Comment`
field calls this out explicitly as a "Pure Task Token Pattern - No SQS"). Full graph:
[`architecture/orchestration.md`](../architecture/orchestration.md).

## Cross-cutting

<table>
<tr>
<td align="center"><img src="icons/cloudwatch.png" width="40"><br><sub>CloudWatch</sub></td>
<td align="center"><img src="icons/xray.png" width="40"><br><sub>X-Ray</sub></td>
<td align="center"><img src="icons/iam.png" width="40"><br><sub>IAM</sub></td>
</tr>
</table>

Observability and security aren't specific to either pattern - every service and every agent in both
diagrams above reports through CloudWatch/X-Ray and runs under its own IAM role.

---

**Icon credit:** service icons are AWS's official [Architecture Icons](https://aws.amazon.com/architecture/icons/),
used under AWS's icon usage guidelines to describe how AWS services are used in this project. This
repository is not affiliated with or endorsed by Amazon Web Services.
