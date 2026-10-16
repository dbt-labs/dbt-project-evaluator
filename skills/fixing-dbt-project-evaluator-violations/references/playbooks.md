# Fix recipes by category

Each recipe says what to change and what the check must show afterwards. File names are examples: use the paths the row gives (`original_file_path`, `current_file_path`, `change_file_path_to`).

Recipes marked *(run)* were applied on a scratch project and the count of their check dropped as expected; the others are guidance that needs the project's context.

## Documentation

**`fct_undocumented_models`** *(run)*: add a description in the YAML next to the model, or in a docs block when the text is long or shared.

```yaml
models:
  - name: stg_orders
    description: Orders as received from the shop, one row per order.
```

```yaml
models:
  - name: stg_orders
    description: "{{ doc('stg_orders') }}"   # with {% docs stg_orders %}...{% enddocs %} in a .md file
```

**`fct_undocumented_source_tables`** and **`fct_undocumented_sources`** *(run)*: the table needs a description, and so does the source itself (the top-level `sources:` entry; one row per source).

```yaml
sources:
  - name: raw_crm
    description: Raw CRM data.        # fct_undocumented_sources
    tables:
      - name: contacts
        description: Raw contacts.    # fct_undocumented_source_tables
```

**`fct_documentation_coverage`**: project-wide. It goes away when `documentation_coverage_target` is reached by fixing the checks above. Do not lower the target.

## Testing

**`fct_missing_primary_key_tests`** *(run)*: find the grain of the model (ask if it is not obvious from the SQL), then test it with `unique` and `not_null` on a single column, or with a combination of columns.

```yaml
models:
  - name: stg_customers
    columns:
      - name: customer_id
        data_tests: [unique, not_null]
```

```yaml
models:
  - name: stg_order_lines
    data_tests:
      - dbt_utils.unique_combination_of_columns:      # needs the dbt_utils package
          arguments:
            combination_of_columns: [order_id, line_number]
```

The accepted combinations are the var `primary_key_test_macros` (default: `unique` + `not_null`, or `dbt_utils.unique_combination_of_columns`). A `not_null` *constraint* is not counted yet (dbt-labs/dbt#16553): keep the test as well. Snapshots, seeds and sources are checked only if `enforced_primary_key_node_types` lists them.

**`fct_sources_without_freshness`** *(run)*: add a threshold and the column that holds the load time, on the source (inherited by its tables) or on a table.

```yaml
sources:
  - name: raw_crm
    config:
      freshness:
        warn_after: {count: 24, period: hour}
      loaded_at_field: _loaded_at
```

`freshness: null` on a table turns it off for that table, which the check treats as no threshold: do not use it to clear the violation.

**`fct_test_coverage`**: project-wide; it follows `fct_missing_primary_key_tests` and the models without any test. Add tests that mean something; do not add `not_null` on a column that can be null just to count.

## Governance

**`fct_public_models_without_contract`** *(run)*: enforce the contract and give every column its `data_type`, otherwise the model fails to build.

```yaml
models:
  - name: fct_orders
    config:
      access: public
      contract: {enforced: true}
    columns:
      - name: order_id
        data_type: int
      - name: customer_id
        data_type: int
```

Take the types from the relation in the warehouse (describe it) or from the SQL; a wrong type fails the next build.

**`fct_undocumented_public_models`** *(run)*: describe the model and every column (see the example above).

**`fct_exposures_dependent_on_private_models`**: an exposure may depend on public models only. Make the parent public with a contract and documentation, or point the exposure at a public model. Making a model public lets other projects `ref()` it: confirm it with the user.

## Modeling

These change the DAG: propose the plan, then do one check at a time.

**`fct_direct_join_to_source`**, **`fct_marts_or_intermediate_dependent_on_source`**, **`fct_multiple_sources_joined`** *(run for the first)*: create a staging model per source table and select from it.

```sql
-- models/staging/raw_shop/stg_raw_shop__customers.sql
select id as customer_id, name as customer_name
from {{ source('raw_shop', 'customers') }}
```

Then replace `{{ source('raw_shop', 'customers') }}` by `{{ ref('stg_raw_shop__customers') }}` in the model the row names, and give the staging model a description and primary key tests. The staging model goes in `models/staging/<source_name>/` and starts with a prefix of `staging_prefixes`.

**`fct_source_fanout`** *(run)*: a source table should have exactly one child, its staging model. Re-point every other model to that staging model.

**`fct_unused_sources`**: ask why the table is declared. Remove it from the YAML if nobody needs it, or build the staging model that should use it.

**`fct_duplicate_sources`**: two source entries point at the same table (`source_relation`). Keep one, delete the other and re-point its `source()` calls. If both are needed for different `loaded_at_field`s, ask the user.

**`fct_root_models`**: a model without parents reads a hard-coded table. Replace it with `source()` or `ref()`. Some are legitimate (a generated date spine): leave those to the user to accept as an exception.

**`fct_staging_dependent_on_staging`**: staging models read sources only. Put the shared cleanup in a `base_` model that both staging models select from, or move the logic that needs another staging model to an intermediate model.

**`fct_staging_dependent_on_marts_or_intermediate`**: a staging model must not read downstream models. Select from the source (through its own staging model) or move the model to the intermediate layer.

**`fct_rejoining_of_upstream_concepts`**: `parent` -> `parent_and_child` -> `child` and `parent` -> `child`. Fold the logic of `parent_and_child` into `child` (or into `parent`) and delete it when nothing else uses it. Check its exposures and tests first.

**`fct_too_many_joins`**: group related joins into intermediate models so that each model joins fewer than `too_many_joins_threshold` parents. Do not raise the threshold.

**`fct_model_fanout`**: the model feeds many leaf models. Move shared logic upstream into one intermediate model, or leave the shaping to the BI layer; this is a design decision for the user.

## Performance

**`fct_chained_views_dependencies`** *(run)*: materialize a model in the middle of the chain, preferably one that many models use, as a table (or incremental when it is large).

```sql
-- models/intermediate/int_chain_4.sql
{{ config(materialized='table') }}
select * from {{ ref('int_chain_3') }}
```

Or for a folder in `dbt_project.yml`: `models: my_project: intermediate: +materialized: table`. The distance is counted over views and ephemeral models, so one table in the chain resets it. Mention the cost (build time and storage) to the user.

**`fct_exposure_parents_materializations`** *(run)*: parents of an exposure must be tables or incremental. Set `materialized` on the model the row names; if the parent is a source, build a model on top of it and point the exposure at that model.

```yaml
exposures:
  - name: orders_dashboard
    depends_on:
      - ref('fct_orders_summary')       # a table, not source('raw_shop', 'orders')
```

## Structure

Moves and renames: ask first, do them with the version control tool (`git mv`) so that history follows, and run `dbt parse` straight after.

**`fct_model_directories`** *(run)*: move the file from `current_file_path` to `change_file_path_to`, together with its YAML if the YAML only describes this model. If the target says `<no folder configured for other>`, either give the model a prefix of its type or set `other_folder_name` in the vars; do not invent a folder.

**`fct_source_directories`**: move the source YAML to `change_file_path_to`.

**`fct_test_directories`** *(run)*: move the tests of the model out of `current_properties_yml_file_path` into a YAML in `change_properties_yml_directory_to`, next to the model (create the file when none exists), then delete the entry from the old file.

**`fct_model_naming_conventions`** *(run)*: rename the model with a prefix from `appropriate_prefixes`.

1. Rename the file and, if the YAML names the model, its `name`.
2. Update every `ref('old_name')`, the `depends_on` of exposures, tests that reference the model, `meta`, semantic models and metrics.
3. Keep the table name that consumers use: `{{ config(alias='old_name') }}`, unless the user wants the new name in the warehouse.
4. `dbt parse`, then `dbt check` for the whole project: the rename can clear other checks (it did for the test directory when the tests moved with the model) and must not create new ones.
5. If the model is `public`, other projects may ref it: ask before renaming.
