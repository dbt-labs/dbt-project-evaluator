

Each rule is a native [dbt check](https://docs.getdbt.com/docs/build/checks) that returns one row per violation. Run it with `dbt check <rule_name>`, for example `dbt check fct_undocumented_models`.
# Documentation

## Documentation Coverage

??? example "`fct_documentation_coverage`"

    ```sql
    --8<-- "checks/documentation/fct_documentation_coverage.sql"
    ```

`fct_documentation_coverage` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/checks/documentation/fct_documentation_coverage.sql)) calculates the percent of enabled models in the project that have
a configured description.

This check returns a single row, and so warns on `dbt check` and `dbt build` (by default), only when `documentation_coverage_pct` is below `documentation_coverage_target` (default 100%). It always looks at the whole project, even when you use `--select`.
You can set your own threshold by overriding the `documentation_coverage_target` variable. [See overriding variables section.](../customization/overriding-variables.md)

**Reason to Flag**

Good documentation for your dbt models will help downstream consumers discover and understand the datasets which you curate for them.
The documentation for your project includes model code, a DAG of your project, any tests you've added to a column, and more.

**How to Remediate**

Apply a text [description](https://docs.getdbt.com/docs/building-a-dbt-project/documentation#related-documentation) in the model's `.yml` entry, or create a [docs block](https://docs.getdbt.com/docs/building-a-dbt-project/documentation#using-docs-blocks) in a markdown file, and use the `{{ doc() }}`
function in the model's `.yml` entry.

!!! note "Tip"

    We recommend that every model in your dbt project has at minimum a model-level description. This ensures that each model's purpose is clear to other developers and stakeholders when viewing the dbt docs site.

## Undocumented Models

`fct_undocumented_models` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/checks/documentation/fct_undocumented_models.sql)) lists every model with no description configured.

**Reason to Flag**

Good documentation for your dbt models will help downstream consumers discover and understand the datasets which you curate for them.
The documentation for your project includes model code, a DAG of your project, any tests you've added to a column, and more.

**How to Remediate**

Apply a text [description](https://docs.getdbt.com/docs/building-a-dbt-project/documentation) in the model's `.yml` entry, or create a [docs block](https://docs.getdbt.com/docs/building-a-dbt-project/documentation#using-docs-blocks) in a markdown file, and use the `{{ doc() }}`
function in the model's `.yml` entry.

!!! note "Tip"

    We recommend that every model in your dbt project has at minimum a model-level description. This ensures that each model's purpose is clear to other developers and stakeholders when viewing the dbt docs site. Missing documentation should be addressed first for marts models, then for the rest of your project, to ensure that stakeholders in the organization can understand the data which is surfaced to them.

## Undocumented Source Tables

`fct_undocumented_source_tables` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/checks/documentation/fct_undocumented_source_tables.sql)) lists every source table with no description configured.

**Reason to Flag**

Good documentation for your dbt sources will help contributors to your project understand how and when data is loaded into your warehouse.

**How to Remediate**

Apply a text [description](https://docs.getdbt.com/docs/building-a-dbt-project/documentation) in the table's `.yml` entry, or create a [docs block](https://docs.getdbt.com/docs/building-a-dbt-project/documentation#using-docs-blocks) in a markdown file, and use the `{{ doc() }}`
function in the table's `.yml` entry.
```
sources:
  - name: my_source
    tables:
      - name: my_table
        description: This is the source table description
```

## Undocumented Sources

`fct_undocumented_sources` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/checks/documentation/fct_undocumented_sources.sql)) lists every source with no description configured.

**Reason to Flag**

Good documentation for your dbt sources will help contributors to your project understand how and when data is loaded into your warehouse.

**How to Remediate**

Apply a text [description](https://docs.getdbt.com/docs/building-a-dbt-project/documentation) in the source's `.yml` entry, or create a [docs block](https://docs.getdbt.com/docs/building-a-dbt-project/documentation#using-docs-blocks) in a markdown file, and use the `{{ doc() }}`
function in the source's `.yml` entry.
```
sources:
  - name: my_source
    description: This is the source description
    tables:
      - name: my_table
```