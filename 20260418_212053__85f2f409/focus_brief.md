# Focus Brief — 20260418_212053__85f2f409

- **Repo**: `museum_artifact_large`
- **Run**: `20260418_212053`
- **Tracks**: A
- **Primary track**: A
- **Cause family**: organic_data_evolution
- **Difficulty**: depth=3

## Scenario

- **Business trigger**: The risk_preparedness_score in int_exhibition_risk_profile produces a false negative by computing risk_preparedness_score=0 for uninsured exhibitions that actually have HIGH financial exposure due to budget overruns. Exhibitions like EXH-2017-02 (6.25% overrun, $425K actual cost), EXH-2020-02 (5.56% overrun, $475K actual cost), and EXH-2013-01 (5.56% overrun, $950K actual cost) have zero coverage despite elevated financial risk.
- **Actor / context**: —
- **Time window**: —

The risk_preparedness_score in int_exhibition_risk_profile produces a false negative by computing risk_preparedness_score=0 for uninsured exhibitions that actually have HIGH financial exposure due to budget overruns. Exhibitions like EXH-2017-02 (6.25% overrun, $425K actual cost), EXH-2020-02 (5.56% overrun, $475K actual cost), and EXH-2013-01 (5.56% overrun, $950K actual cost) have zero coverage despite elevated financial risk.

- Exhibition curators across multiple halls have been managing tight budgets that occasionally slip into overrun territory. The financial teams noticed that several exhibitions with budget overruns had zero insurance coverage, yet the risk_preparedness_score showed 0 for all of them. This created a dangerous illusion: a score of 0 implied "no risk" when in fact these exhibitions had the highest financial exposure. When the risk management dashboard was reviewed by the board, these exhibitions appeared adequately prepared simply because they had emergency plans in place, while their uninsured status went unnoticed.
- Exhibition curators have been overspending exhibition budgets without corresponding insurance coverage increases. A recent audit revealed that three major exhibitions—EXH-2017-02, EXH-2020-02, and EXH-2013-01—exceeded their approved budgets by 30% due to last-minute artifact acquisitions and facility upgrades. Despite the increased financial exposure, no additional insurance policies were purchased to cover the overruns. The risk_preparedness_score currently shows 0 for these exhibitions, creating a false sense of security in the risk management dashboard.
- Exhibition curators at the museum have been allocating increasing budgets to traveling and special exhibitions while deferring insurance coverage renewals. Recently, three exhibitions—EXH-2017-02 (Sounds of Antiquity: Ritual Bells of the Bronze Age), EXH-2020-02 (Gold and Silver: Metalwork of the Tang Dynasty), and EXH-2013-01 (The Five Great Wares: Masterpieces of Song Ceramics)—experienced budget overruns ranging from 5.5% to 6.25%. While these exhibitions have active emergency response plans in their respective halls, their insurance policies were allowed to lapse during budget reallocation cycles. The museum's risk_preparedness_score treats these uninsured high-exposure exhibitions identically to exhibitions with no emergency plans at all, showing a score of 0 rather than flagging the coverage gap. This creates a coverage illusion where the presence of emergency protocols masks the absence of financial protection, leading risk management dashboards to incorrectly conclude these exhibitions are adequately prepared.

## Affected models

- `int_exhibition_risk_profile`
- `mart_risk_management_dashboard`

## Candidate reports

- RiskManagementReport

## Investigation hints

- 3 actionable event(s) and 0 noise event(s) seeded in the window.
- Start from `events/event_log.jsonl` and cross-reference the affected models/reports above.
- Authoritative ground truth lives in the root `ground_truth.yaml`; per-track artefacts are under `evaluation/`.
