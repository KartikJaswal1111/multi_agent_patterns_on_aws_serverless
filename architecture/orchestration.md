# Orchestration Architecture

A single Step Functions state machine owns the sequence. Agents still run as independent Lambda
functions, but the workflow definition — not the agents themselves — controls order, parallelism,
and branching.

```mermaid
flowchart TD
    Start(["Execution start"]) --> PlannerExtract["Task: PlannerExtract\nLambda"]
    PlannerExtract --> Parallel{{"Parallel state"}}

    Parallel --> WeatherGet["Task: WeatherGet\nLambda"]
    Parallel --> FlightSearch["Task: FlightSearch\nLambda"]

    WeatherGet --> PlannerAnalyze["Task: PlannerAnalyzeAndBook\nLambda"]
    FlightSearch --> PlannerAnalyze

    PlannerAnalyze --> Choice{"CheckPlannerDecision"}
    Choice -->|needs review| WaitForHuman[["WaitForHuman\ntask token"]]
    Choice -->|book| Finalize["Task: PlannerFinalizeBooking"]
    Choice -->|default| HandleError["HandleError"]

    WaitForHuman --> Decision{"ProcessHumanDecision"}
    Decision -->|approved| Finalize
    Decision -->|rejected| Rejected(["BookingRejected"])
    Decision -->|timeout| Timeout(["HumanReviewTimeout"])

    Finalize --> Success(["BookingSuccess"])

    classDef bus fill:#0b5cab,color:#ffffff,stroke:#063b73,stroke-width:2px;
    classDef agent fill:#e8f1fb,color:#0b3d66,stroke:#0b5cab,stroke-width:1.5px;
    classDef ext fill:#f2f2f2,color:#333333,stroke:#999999,stroke-width:1px;
    class Parallel,Choice,Decision bus;
    class PlannerExtract,WeatherGet,FlightSearch,PlannerAnalyze,Finalize agent;
    class Start,WaitForHuman,HandleError,Rejected,Timeout,Success ext;
```

**Legend:** blue diamonds/hexagons = control-flow states owned by the state machine itself (parallel
branch, choice, human wait) · light-blue boxes = `Task` states invoking an agent Lambda · grey =
terminal/pass states.

**One graph, one audit trail.** Every state's input/output is inspectable after execution, and the
human-approval branch (`WaitForHuman` / `ProcessHumanDecision`) is a structural part of the
definition rather than something reconstructed from logs. See
[`../docs/02-orchestration-pattern.md`](../docs/02-orchestration-pattern.md) for the walkthrough and
[`../docs/03-human-in-the-loop.md`](../docs/03-human-in-the-loop.md) for how the approval step
compares to choreography's approach to the same problem.
