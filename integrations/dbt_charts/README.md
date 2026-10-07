# Dashboard (dbt-charts)

A [dbt-charts](https://github.com/dbt-labs/dbt-charts) board
(`project_evaluator.yml`) built from this package's output, as tabs:

- **Overview** (the default tab) - high-level: total findings, rules passing
  vs. failing, findings ranked by rule, test/documentation coverage by model
  layer, and a full rule scorecard. Start here to see where to look.
- **One tab per rule category** (Documentation, Governance, Modeling,
  Performance, Structure, Testing) - one table per rule, listing the actual
  offending models/sources/tests for every rule that has findings. Click
  into these once the Overview tab has told you which rules to dig into -
  they show exactly what to fix, not just how much. An empty table just
  means that rule has no findings (it's passing).

> **Prerequisite: every rule in this package must be enabled.** Both
> `fct_rule_findings_summary` (which the Overview tab reads) and the
> dashboard's own per-rule tabs reference every rule's `fct_` model -
> and `fct_test_coverage`/`fct_documentation_coverage` - directly and
> unconditionally, with no way to skip one. If you've disabled any rule
> via `+enabled: false` (see
> [Disabling checks from the package](../../docs/customization/customization.md)),
> don't enable this dashboard until you re-enable it: a disabled model's
> `ref()` fails compilation outright (for `fct_rule_findings_summary`) or
> errors that one chart (for a per-rule tab query), rather than just
> leaving something empty.

## Setup

1. Install dbt-charts with the extra for your adapter (requires Python
   <3.14; `dbt-charts>=0.8.0`). dbt-charts currently ships extras for
   Athena, BigQuery, ClickHouse, Databricks, PostgreSQL, Redshift,
   Snowflake, Spark, and Trino (plus DuckDB, built in) - Fabric, SQL
   Server, and Synapse, which this package otherwise supports, aren't
   covered, so this board won't run against those.

   ```bash
   pip install "dbt-charts[snowflake]>=0.8.0"
   ```

   or

   ```bash
   uv tool install "dbt-charts[snowflake]>=0.8.0" --python 3.13
   ```

2. Confirm no rule is disabled anywhere in your project (see the
   prerequisite above), then set `rule_findings_summary_enabled: true` in
   your `vars:` block - it's disabled by default so that projects which
   don't use this dashboard aren't forced to have every rule enabled. Then
   build this package's models, from your project root:

   ```bash
   dbt build --select package:dbt_project_evaluator
   ```

   (`--vars '{rule_findings_summary_enabled: true}'` works too for a
   one-off build, but won't persist to the next `dbt build` you run
   without it - set the var in `dbt_project.yml` so it stays on.)

3. Set your dbt profile name as an environment variable, once, in your
   shell profile or CI env (the same profile you already use for `dbt build`):

   ```bash
   export DBT_PROJECT_EVAL_PROFILE=<your dbt profile name>
   ```

   This does not go in a file: `dbt_packages/` is fully wiped and re-cloned
   by every `dbt deps`, so anything written into a file there is silently
   lost on the next install. The env var lives outside `dbt_packages/` and
   survives every future `dbt deps`.

4. Launch:

   ```bash
   cd dbt_packages/dbt_project_evaluator/integrations/dbt_charts
   dct validate
   dct serve
   ```

   `dct serve` prints the URL it's bound to (defaults to
   `http://localhost:8501/project_evaluator/`). To render a static
   snapshot instead of serving live:

   ```bash
   dct render charts/project_evaluator.yml --format html --output /path/to/output.html
   ```

## If your project uses a custom package install path

If `packages-install-path` in your `dbt_project.yml` is not the default
`dbt_packages`, the relative path this board uses to find your project's
`dbt_project.yml` and manifest will not resolve. Point dct at your project
root explicitly instead:

```bash
dct render charts/project_evaluator.yml --dbt-project-dir /path/to/your/project
```

(or set the `DBT_PROJECT_DIR` environment variable to the same path).
