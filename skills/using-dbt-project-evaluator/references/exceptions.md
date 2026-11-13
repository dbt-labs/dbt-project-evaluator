# Accepting violations: dbt_project_evaluator_exceptions

Only add an exception after the user confirmed the violation is intentional. Ask for the reason and write it as a comment next to the entry.

## Shape

A mapping from a **check name** to a list of **entries**. A name that is not a check of the package is a compile error that lists the valid names (see [check-columns.md](check-columns.md)). The two coverage checks cannot have exceptions.

```yaml
fct_model_naming_conventions:
  - stg_legacy_%                        # a string
fct_staging_dependent_on_staging:
  - {name: stg_a, parent: stg_b}        # a mapping of columns
  - parent: stg_base_%
fct_unused_sources: raw_shop.orders     # a single string is accepted instead of a list
```

## Entries

- **String**: a SQL `LIKE` pattern compared with the name of the resource the violation points at (the `unique_id` column of the check) and with its whole `unique_id`. Names: `stg_orders` for a model, `int_model.v2` for a version of a versioned model (the bare name does not match), `source_name.table_name` for a source table. `%` is any sequence, `_` any single character; matching is case-sensitive. Examples: `stg_%_unioned`, `raw_shop.orders`, `model.my_project.stg_orders`, `model.%.stg_legacy_%`.
- **Mapping**: `{column: pattern}` on the columns the check returns (see [check-columns.md](check-columns.md); run the check to see them). All the keys of one mapping must match (AND), which accepts exactly one pair: `{name: stg_a, parent: stg_b}`. A column can have several patterns: `{parent: [stg_x%, stg_y%]}` (any of them). Separate entries are alternatives (OR).
- **List columns** (`source_parents`, `model_parents`, `leaf_children`, `model_children`): the entry matches when **any element** matches, and then the whole violation is dropped, not just that parent.
- Path columns can accept a folder: `{original_file_path: models/utils/%}`.
- Errors: an unknown column fails with DuckDB's message `does not have a column named "x"`; an empty mapping, a column without a pattern and a column name that is not a plain identifier are compile errors.

## Where to write them

In a var:

```yaml
vars:
  dbt_project_evaluator_exceptions:
    fct_multiple_sources_joined:
      - stg_%_unioned
```

Or, for long lists with comments, in a macro of the project (any file under `macro-paths`). The package dispatches `dbt_project_evaluator_exceptions`, so the project's own `default__` implementation replaces the var (the var is only read if the macro reads it):

```sql
{% macro default__dbt_project_evaluator_exceptions() %}

{% set exceptions %}

# stg_..._unioned models union identical sources on purpose
fct_multiple_sources_joined:
  - stg_%_unioned

# the legacy CRM sources are kept for audit
fct_unused_sources:
  - raw_crm.%

{% endset %}

{{ return(fromyaml(exceptions)) }}

{% endmacro %}
```

## Exceptions declared on the resources (SQL condition)

When the reason is something the project already declares on the resources (`meta`, for a folder in `dbt_project.yml` or a single resource in its YAML), define the second dispatched macro, `default__dbt_project_evaluator_exception_sql(check_name)`. It returns a SQL condition (or a list of them) that is true for the violations to accept, added to the entries above. Use `violation.<column>` for the columns of the check and `info_schema('models')`, `info_schema('sources')`... for the rest; a `NULL` condition accepts nothing.

```sql
{% macro default__dbt_project_evaluator_exception_sql(check_name) %}
violation.unique_id in (
    {% for relation in ['models', 'sources', 'snapshots'] %}
    select unique_id from {{ info_schema(relation) }}
    where list_contains(coalesce(from_json(json_extract(meta, '$.dbt_project_evaluator.exceptions'), '["VARCHAR"]'), []), '{{ check_name }}')
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
)
{% endmacro %}
```

```yaml
models:
  my_project:
    legacy:
      +meta: {dbt_project_evaluator: {exceptions: [fct_model_directories]}}   # folder; or `config: meta:` on one model
```

Which level to propose: the var first; the macro for long lists with comments; the SQL condition only for rules (a folder, an owner) the user wants to keep with the resources. Pairs and columns stay in the var or the macro. The `meta` must be on the resource in the `unique_id` column; exposures have no `meta` for checks yet (dbt-labs/dbt#16584), so `fct_exposure_parents_materializations` and `fct_exposures_dependent_on_private_models` need the var or the macro; a misspelled check name in `meta` is not detected (it accepts nothing), so verify the count drops.

## Verify

Run the check before and after: `dbt check <check>`. The count in `found with N violation(s)` must drop by exactly the number of resources you meant to accept. If it did not move, the pattern did not match (check the name, the version suffix, the case, the column); if it dropped too much, the pattern is too broad.
