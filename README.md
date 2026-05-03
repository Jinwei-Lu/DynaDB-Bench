# DynaDB-Bench

DynaDB-Bench is a benchmark dataset and evaluation protocol for measuring how
AI agents maintain data pipelines under silent semantic drift.

Agents receive a noisy database change log and a runnable data-engineering
workspace. Some events are true business-semantics changes that should trigger
SQL and narrative repairs; other events are noise and should not be modified
around. The pipeline still runs under the new database state, so the agent must
reconstruct the correct behavior from the event log, the repository, lineage,
and data evidence rather than relying on failing tests.

This repository currently contains the dataset README only. The generated
benchmark artifacts, source database snapshots, and evaluation outputs are not
included in this README-only upload.

## Task

Each instance is an event-log-driven silent staleness response task:

1. Read `event_log.jsonl` for the observed transition from state `S1` to `S2`.
2. Triage events into signal events and noise events.
3. Trace every signal event through SQL model lineage and report narratives.
4. Repair affected SQL views and narrative sections.
5. Submit a `RestorationManifest` containing all changes plus explicit
   no-change decisions for reviewed but unaffected surfaces.

The expected agent behavior is deliberately not reducible to "fix a failing
test". In many instances the old pipeline still executes successfully, but its
outputs are stale with respect to the new business semantics.

## Inputs

A benchmark instance is expected to provide:

- `event_log.jsonl`: noisy event stream for the observation window.
- A data-engineering repository with staging, intermediate, mart, and report
  layers.
- An `S2` database state in which the old pipeline remains executable.
- Optional ablation hints for scope-guided or triage-guided evaluation modes.

The public release plan uses a two-layer structure:

- `repos/`: reusable generated data-engineering repositories.
- `instances/`: event-window scenarios derived from those repositories.

Each instance references a repo and includes its own task metadata, event log,
ground truth, and evaluation configuration.

## Outputs

Agents submit a `RestorationManifest` with:

- SQL changes for affected views.
- Narrative/report changes for affected claims or sections.
- No-change decisions for surfaces that were inspected and determined to be
  unaffected.
- Evidence and reasoning fields used by the evaluator to check triage,
  impact tracing, restraint, and repair quality.

## Evaluation

DynaDB-Bench reports four primary metrics:

- `Variant OER`: outcome equivalence under held-out data variants.
- `Restraint Precision`: avoidance of unnecessary changes to unaffected
  surfaces.
- `Reasoning Validity`: validity of submitted invariants, source queries,
  thresholds, and no-change justifications.
- `Narrative Quality`: judge-backed assessment of narrative repairs under a
  controlled rubric.

The default aggregate score is:

```text
DynaDB Score = harmonic_mean(
  Variant OER,
  Restraint Precision,
  Reasoning Validity,
  Narrative Quality
)
```

The benchmark also includes a No-Op baseline and ablation modes that isolate
event-log usage, scope discovery, and triage difficulty.

## Construction

DynaDB-Bench is built from industrial-scale PostgreSQL databases and
LLM-assisted benchmark synthesis:

- Stage B builds executable data-engineering repos from source databases.
- Stage I derives event-driven benchmark instances from those repos.
- Stage V validates benchmark quality.
- Stage E evaluates agents and produces leaderboard reports.

The source database pool is based on LiveSQLBench-Large-v1. DynaDB-Bench adds
new generated repositories, event logs, silent-staleness scenarios, reference
repairs, and evaluation artifacts on top of the source data.

## Usage

The implementation repository exposes the main workflows through:

```bash
python -m dynadb.cli build --db <db_name> --output-dir repos/<db_name>
python -m dynadb.cli derive --repo repos/<db_name>
python -m dynadb.cli validate sanity --instances instances/ --repos repos/
python -m dynadb.cli evaluate --instances instances/ --repos repos/
```

The dataset artifacts are expected to be consumed by the `evaluate` command or
by compatible agent harnesses that implement the same workspace and manifest
contracts.

## License And Attribution

This README-only upload does not redistribute source database snapshots or
generated benchmark artifacts. Source data attribution and generated artifact
licensing should be reviewed with the full dataset release package.

LiveSQLBench-Large-v1 is used as the source database pool for the planned
benchmark construction pipeline.

## Citation

Citation information will be added with the full dataset release.
