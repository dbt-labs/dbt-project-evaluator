# Querying the DAG with SQL

Version 1 of the package created models in your warehouse (`int_all_dag_relationships`, `int_all_graph_resources`, `stg_columns`...) to describe your project. Version 2 doesn't build anything in your warehouse: the same information is available in the dbt information schema, which you can query with SQL using `dbt show`.

## Querying the information schema

First, generate the information schema of your project:

```bash
dbt parse --generate-info-schema
```

!!! note

    `dbt parse` doesn't write everything. Column types, column-level lineage and runtime results are only written by `dbt compile`, `dbt run` or `dbt build` when they are run with `--generate-info-schema`.

Then query any of its views with `info_schema()`:

```bash
dbt show --inline "select parent_unique_id, child_unique_id from {{ info_schema('edges') }} limit 10"
```

or print an entire view with `--info`:

```bash
dbt show --info models --limit 5
```

Use `--limit -1` to remove the default limit on the number of rows displayed.

The queries are executed locally (in DuckDB), and not in your warehouse. The views available are `project`, `packages`, `project_vars`, `project_env_vars`, `models`, `seeds`, `snapshots`, `functions`, `analyses`, `hooks`, `checks`, `sources`, `data_tests`, `unit_tests`, `macros`, `groups`, `exposures`, `metrics`, `docs_blocks`, `saved_queries`, `semantic_models`, `semantic_entities`, `semantic_measures`, `semantic_dimensions`, `semantic_relationships`, `time_spines`, `dag_nodes`, `edges`, `node_columns`, `column_lineage`, `classifiers` as well as some views about the invocations (`invocations`, `run_results`, `freshness`, `relations`, `diagnostics`, `adapter_queries`).

!!! note

    The views a check can query when it runs are a subset of those. For example, `raw_code` and `constraints` are available to `dbt show` but not to checks.

The view `edges` contains the direct dependencies between all the nodes of the project, including the tests and the macros. Filter on the prefix of `unique_id` (`model.`, `source.`, `exposure.`...) to only keep what you need. The indirect dependencies can be retrieved with a recursive query.

## Examples

### Listing all the sources used by an exposure

```sql
with recursive upstream as (
    select parent_unique_id, child_unique_id
    from {{ info_schema('edges') }}
    where child_unique_id = 'exposure.my_project.orders_dashboard'

    union

    select e.parent_unique_id, e.child_unique_id
    from {{ info_schema('edges') }} e
    join upstream u on e.child_unique_id = u.parent_unique_id
)

select distinct parent_unique_id
from upstream
where parent_unique_id like 'source.%'
```

Following the edges in the other direction gives the list of the exposures or metrics that use a given source.

### Reviewing the models with the most direct dependents

```sql
select parent_unique_id as model, count(*) as direct_dependents
from {{ info_schema('edges') }}
where parent_unique_id like 'model.%'
  and child_unique_id not like 'test.%'
group by 1
order by 2 desc
limit 10
```

### Identifying the models with the most lines of code

```sql
select name, length(raw_code) - length(replace(raw_code, chr(10), '')) + 1 as lines_of_code
from {{ info_schema('models') }}
where enabled
order by lines_of_code desc
limit 10
```

### Finding columns without a description

The view `node_columns` (replacing `stg_columns`) lists the columns configured in the YAML files. It doesn't list the columns that haven't explicitly been added to the YAML files.

```sql
select node_unique_id, column_name
from {{ info_schema('node_columns') }}
where coalesce(trim(description), '') = ''
```

The same view helps answering questions such as:

- Are there columns with the same name in different nodes?
- Do any columns share the same name but have different descriptions?
- Are there columns with names that match a specific pattern?
- Have any prohibited names been used for columns?

## Other things you can do with it

Using the results of those queries, for example in a dashboard or a report, allows to:

- list all the sources used by a given exposure, or all the exposures or metrics using a given source
- follow the evolution of the number of models, metrics and exposures over time
- identify the longest "chains" of models in a project and potential bottlenecks
- review models with many/few direct dependents

## Defining additional checks that match your exact requirements

The queries above can also be turned into your own native checks, that run alongside the ones from the package. Create a SQL file in the `checks` folder of your project: the check passes when the query returns no row and each row returned is a violation. Your `dbt_project.yml` must also declare the version of the information schema used by your checks:

```yaml title="dbt_project.yml"
info_schema:
  version: 1
```

See the [documentation on dbt checks](https://docs.getdbt.com/docs/build/checks) and the [checks of this package](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/checks) for examples.
