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

## Verify

Run the check before and after: `dbt check <check>`. The count in `found with N violation(s)` must drop by exactly the number of resources you meant to accept. If it did not move, the pattern did not match (check the name, the version suffix, the case, the column); if it dropped too much, the pattern is too broad.
