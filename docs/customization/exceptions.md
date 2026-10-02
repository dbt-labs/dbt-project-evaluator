# Configuring exceptions to the rules

While the rules defined in this package are considered best practices, we realize that there might be exceptions to those rules and people might want to exclude given results to get passing checks despite not following all the recommendations.

An example would be excluding all models with names matching with `stg_..._unioned` from `fct_multiple_sources_joined` as we might want to union 2 different tables representing the same data in some of our staging models and we don't want the check to report those models.

This is what the variable `dbt_project_evaluator_exceptions` is for. It replaces the seed `dbt_project_evaluator_exceptions.csv` of version 1. Exceptions can also be declared in macros, or in the config of the resources: see [where to declare the exceptions](#where-to-declare-the-exceptions) to choose.

!!! info "Coming from version 1?"

    If you used the seed, you don't have to rewrite it by hand: run `python dbt_packages/dbt_project_evaluator/scripts/migrate_to_v2.py` from the root of your project. It reads the seed and writes the equivalent macro in `macros/dbt_project_evaluator_exceptions.sql` (or a `vars:` snippet with `--format var`). The rows it cannot translate are never dropped: they are written as `# NEEDS REVIEW` comments with the reason. The script is optional; see [migrating to version 2](../migrating-to-v2.md#3-convert-the-exceptions) for where to get it and how to run it.

## Accepting violations of a check

The exceptions are a mapping from the **name of a check** to a **list of entries**. An entry is either a pattern, or a mapping from columns of the check to patterns:

```yaml
fct_root_models:
  - dim_calendar                              # a pattern: the resource that the violation points at
fct_staging_dependent_on_staging:
  - stg_%_unioned                             # the model to fix
  - parent: stg_base_%                        # a column of the check
  - {name: stg_model_4, parent: stg_model_2}  # several columns: this pair only
```

A violation is accepted, and dropped from the result of the check, as soon as **one** entry of its check matches. Patterns use the SQL [`LIKE`](https://duckdb.org/docs/sql/functions/pattern_matching#like) syntax (`%` matches any sequence of characters, `_` any single character) and are case-sensitive.

### Patterns on the resource

A pattern on its own is compared with the resource that the row points at, in its column `unique_id`: with its name, and with its whole `unique_id`.

| Resource | Name to match | Example pattern |
| -------- | ------------- | --------------- |
| model, seed, snapshot, exposure | `name` | `stg_legacy_%` |
| versioned model | `name.vVERSION`, the bare name doesn't match | `int_model_5.v1` |
| source table | `source_name.table_name` | `raw_shop.orders` |
| anything | the `unique_id` | `model.my_project.stg_legacy_orders` or `model.%.stg_legacy_%` |

To find the name to use, run the check (`dbt check fct_root_models`): the `unique_id` column of the output is the resource that is matched.

### Patterns on a column

Some checks report a relationship between two resources, like a model and one of its parents. To accept a given parent, or a given pair, use a mapping from the **columns that the check returns** to patterns (the columns are the headers of the result of `dbt check <name>`, and are listed [below](#columns-returned-by-the-checks)):

```yaml
fct_staging_dependent_on_staging:
  - parent: stg_base_%                        # any model reading from a model matching stg_base_%
  - {name: stg_model_4, parent: stg_model_2}  # only stg_model_4 reading from stg_model_2
```

- **All the keys of a mapping must match** for the entry to apply. `{name: stg_model_4, parent: stg_model_2}` accepts exactly this pair, not `stg_model_4` reading from another model.
- **Separate entries are alternatives.** A violation is accepted if any entry matches.
- **Several patterns for the same column are alternatives too**: `parent: [stg_base_%, stg_legacy_%]`.
- **A column that holds a list matches when any of its elements does.** This is the case of `source_parents` in `fct_direct_join_to_source` and `fct_multiple_sources_joined`, `model_parents` in `fct_direct_join_to_source`, `leaf_children` in `fct_model_fanout` and `model_children` in `fct_source_fanout`. `source_parents: raw_shop.orders` accepts every row that has `raw_shop.orders` among its sources. The whole row is accepted: the other sources of the row are not reported either.
- The patterns of a column must not be empty, and a mapping can't be empty: those are compile errors.
- A column that the check doesn't return fails the check with a DuckDB error naming it (`Values list "violation" does not have a column named "nope"`): compare with the [columns below](#columns-returned-by-the-checks).

#### Accepting a relationship between two resources

To accept that `int_model_4` reads from the source `source_1.table_2` even though it also reads from a model:

```yaml
fct_direct_join_to_source:
  - {name: int_model_4, source_parents: source_1.table_2}
```

To accept the loop between `stg_model_1` and `int_model_5.v2` only:

```yaml
fct_rejoining_of_upstream_concepts:
  - {parent: stg_model_1, child: int_model_5.v2}
```

### Columns returned by the checks

`fct_documentation_coverage` and `fct_test_coverage` don't use the exceptions. Every other check returns `unique_id`, the resource to fix, and the columns below.

| Check | Columns | To accept... |
| ----- | ------- | ------------ |
| `fct_chained_views_dependencies` | `child`, `parent`, `distance` | `child` is the model at the end of the chain, `parent` the first view of the chain |
| `fct_direct_join_to_source` | `name`, `source_parents`, `model_parents` | `name` is the model that reads from both; the parents are lists of names |
| `fct_duplicate_sources` | `source_name`, `source_relation` | `source_relation` is the table that several sources point at |
| `fct_exposure_parents_materializations` | `exposure_name`, `parent_resource_type`, `parent_resource_name`, `parent_model_materialization` | `exposure_name` and `parent_resource_name` are the two ends |
| `fct_exposures_dependent_on_private_models` | `exposure_name`, `parent_unique_id`, `parent_resource_name`, `parent_resource_type`, `parent_access` | `exposure_name` and `parent_resource_name` are the two ends |
| `fct_marts_or_intermediate_dependent_on_source` | `name`, `model_type`, `source_name` | `name` is the model, `source_name` the source it reads from |
| `fct_missing_primary_key_tests` | `name`, `resource_type` | |
| `fct_model_directories` | `name`, `model_type`, `current_file_path`, `change_file_path_to` | |
| `fct_model_fanout` | `name`, `leaf_children` | `name` is the model with the fanout, `leaf_children` a list of names |
| `fct_model_naming_conventions` | `name`, `model_type`, `appropriate_prefixes`, `original_file_path` | |
| `fct_multiple_sources_joined` | `name`, `source_parents` | `name` is the model, `source_parents` a list of source names |
| `fct_public_models_without_contract` | `name`, `access`, `contract_enforced` | |
| `fct_rejoining_of_upstream_concepts` | `parent`, `parent_and_child`, `child` | `parent` is the model with two paths to `child`, `parent_and_child` the model in between |
| `fct_root_models` | `name`, `original_file_path` | |
| `fct_source_directories` | `source_name`, `current_file_path`, `change_file_path_to` | |
| `fct_source_fanout` | `source_name`, `model_children` | `source_name` is the source, `model_children` a list of names |
| `fct_sources_without_freshness` | `source_name` | |
| `fct_staging_dependent_on_marts_or_intermediate` | `name`, `parent`, `parent_model_type` | `name` is the staging model, `parent` the model it reads from |
| `fct_staging_dependent_on_staging` | `name`, `parent` | `name` is the staging model, `parent` the staging model it reads from |
| `fct_test_directories` | `model_name`, `current_properties_yml_file_path`, `change_properties_yml_directory_to` | |
| `fct_too_many_joins` | `name`, `parent_count` | |
| `fct_undocumented_models` | `name`, `original_file_path` | |
| `fct_undocumented_public_models` | `name`, `is_described_model`, `total_defined_columns`, `total_described_columns` | |
| `fct_undocumented_source_tables` | `source_name`, `original_file_path` | |
| `fct_undocumented_sources` | `source_name`, `original_file_path` | |
| `fct_unused_sources` | `source_name`, `original_file_path` | |

Columns that hold a path, like `original_file_path`, can be used to accept a whole folder: `original_file_path: models/utils/%`.

## Where to declare the exceptions

The package reads the exceptions through three levels, from the simplest to the most flexible. They add up: a violation is accepted as soon as one of them accepts it.

| Level | What you write | Use it when |
| ----- | -------------- | ----------- |
| [The variable](#in-a-variable) `dbt_project_evaluator_exceptions` | A mapping in `dbt_project.yml` | You have a few exceptions, and patterns on names or columns are enough. This is where to start. It is also the only one you can change for a single run with `--vars` |
| [The macro](#in-a-macro) `default__dbt_project_evaluator_exceptions` | The same mapping, built in a macro | The list is long, you want a YAML comment with the reason of every exception, or you build the list from several places (files, targets, other variables) |
| [The macro](#in-the-config-of-the-resources) `default__dbt_project_evaluator_exception_sql` | A SQL condition | The reason for the exception is a property of the resource that you have already declared in your project, like its `meta`, and you would rather declare the exception next to the resource, or for a whole folder, than in a central list |

Recommendations:

- **Start with the variable.** Move to the macro when the list outgrows `dbt_project.yml` or when you want to explain the exceptions. The two use the same entries, so it is a copy and paste.
- **Keep the pairs and the columns in the variable or the macro.** `{name: stg_a, parent: stg_b}` is shorter and checked at compile time there; a SQL condition would repeat the same logic by hand.
- **Use the SQL condition for rules, not for lists.** "Every model of the legacy folder is exempt from `fct_model_directories`" is one line of `meta` on a folder. The same rule as patterns is a list that has to be kept up to date. A rule can also be maintained by the owners of the models instead of the people who run the package.
- **Prefer the first two when both would do.** An unknown check name in the variable or in the first macro is a compile error. In the SQL condition, and in the `meta` that it reads, a typo is not detected: it just accepts nothing.
- Defining the macro `default__dbt_project_evaluator_exceptions` stops the variable from being read, unless your macro reads it. The SQL condition is independent of both.

### In a variable

This is the simplest option. Define the variable in your `dbt_project.yml`, either at the top level of `vars` or under the name of the package:

```yaml title="dbt_project.yml"
vars:
  dbt_project_evaluator_exceptions:
    fct_multiple_sources_joined:
      - stg_%_unioned
    fct_unused_sources:
      - raw_shop.unused_table
```

### In a macro

If the list gets long, or if you want to document every exception, define the macro `default__dbt_project_evaluator_exceptions` in your project. The package calls the macro `dbt_project_evaluator_exceptions` with [`adapter.dispatch`](https://docs.getdbt.com/reference/dbt-jinja-functions/dispatch), which looks for an implementation in your project first. The variable above is only the default implementation: once you define the macro, it is not read anymore, unless your macro does.

Write the exceptions as YAML in a string and parse them with `fromyaml`, so that you can use YAML comments:

```sql title="macros/dbt_project_evaluator_exceptions.sql"
{% macro default__dbt_project_evaluator_exceptions() %}

{% set exceptions %}

# stg_..._unioned models union identical sources on purpose
fct_multiple_sources_joined:
  - stg_%_unioned

# the sources of the legacy CRM are kept for audit and not used yet
fct_unused_sources:
  - raw_shop.unused_table         # source_name.table_name
  - legacy_crm.%

# a pattern is also compared with the whole unique_id
fct_model_naming_conventions:
  - model.%.orders_summary

{% endset %}

{{ return(fromyaml(exceptions)) }}

{% endmacro %}
```

The macro can return anything that builds the same mapping. For example, to complete the variable with a list written in YAML instead of replacing it:

```sql title="macros/dbt_project_evaluator_exceptions.sql"
{% macro default__dbt_project_evaluator_exceptions() %}

{% set exceptions = var('dbt_project_evaluator_exceptions', {}) %}

{% for check_name, patterns in fromyaml(more_exceptions()).items() %}
  {% do exceptions.update({check_name: (exceptions.get(check_name) or []) + patterns}) %}
{% endfor %}

{{ return(exceptions) }}

{% endmacro %}


{% macro more_exceptions() %}
fct_unused_sources:
  - raw_shop.unused_table
{% endmacro %}
```

### In the config of the resources

Patterns match names and columns. When the reason for an exception is something you already declare on the resources, like a `meta` entry, define the macro `default__dbt_project_evaluator_exception_sql` instead. The package calls it once per check, with the name of the check, and adds the SQL condition that it returns to the exceptions above: the violations for which the condition is true are accepted.

In the condition:

- the columns of the check are available as `violation.<column>` (the `unique_id` column is the resource to fix, see the [columns below](#columns-returned-by-the-checks)),
- the [information schema](../querying-the-dag.md) is available with `info_schema('models')`, `info_schema('sources')`...,
- a condition that is `NULL` accepts nothing,
- the macro can return a list of conditions instead of a string: the violation is accepted when any of them is true. Returning nothing, or an empty string, adds no exception.

For example, to accept the violations of the resources that list the check in their `meta`:

```sql title="macros/dbt_project_evaluator_exception_sql.sql"
{% macro default__dbt_project_evaluator_exception_sql(check_name) %}
violation.unique_id in (
    {% for relation in ['models', 'sources', 'snapshots'] %}
    select unique_id
    from {{ info_schema(relation) }}
    where list_contains(
        coalesce(from_json(json_extract(meta, '$.dbt_project_evaluator.exceptions'), '["VARCHAR"]'), []),
        '{{ check_name }}'
    )
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
)
{% endmacro %}
```

The exceptions are then declared where the resources are configured, for a whole folder in `dbt_project.yml`, or for a single resource in its YAML file. Resources inherit the `meta` of their folder and, for a source, of the source itself:

```yaml title="dbt_project.yml"
models:
  my_project:
    legacy:
      +meta:
        dbt_project_evaluator:
          exceptions: [fct_model_directories, fct_root_models]   # for the whole folder
```

```yaml title="models/marts/_marts__models.yml"
models:
  - name: dim_calendar
    config:
      meta:
        dbt_project_evaluator:
          exceptions: [fct_root_models]   # a root model on purpose

sources:
  - name: raw_crm
    config:
      meta:
        dbt_project_evaluator:
          exceptions: [fct_sources_without_freshness]   # for all the tables of the source
```

Things to know about this recipe:

- **The `meta` has to be on the resource that the violation points at**, the one in the `unique_id` column. Declaring it on a parent doesn't accept the violations of its children.
- **It accepts every violation of that resource for that check**, as the entries of the variable do. To accept one pair or one column only, use the variable or the macro.
- **Exposures can't be used yet**: the information schema doesn't give the `meta` of exposures to checks ([dbt-labs/dbt#16584](https://github.com/dbt-labs/dbt/issues/16584)). The two checks whose `unique_id` is an exposure, `fct_exposure_parents_materializations` and `fct_exposures_dependent_on_private_models`, need the variable or the macro. Seeds weren't tested.
- **Nothing validates the names** in the `meta`. If a violation is still reported, check the spelling of the check name and where the `meta` is declared (`dbt ls --select <resource> --output json --output-keys meta` shows the `meta` that a resource ends up with).
- The condition is SQL that runs in DuckDB on every check. A mistake in it fails the check with a DuckDB error, as a wrong column name in an entry does.

### Exceptions are validated

The exceptions are checked every time the project is parsed. An entry that isn't the name of a check of the package, because of a typo for example, is a compile error that lists the names that exist:

```
dbt_project_evaluator_exceptions: 'fct_modl_fanout' is not a check of dbt_project_evaluator. Known checks: fct_chained_views_dependencies, fct_direct_join_to_source, ...
```

An invalid column name, a mapping without any key and a column without a pattern are compile errors as well.

### What exceptions can't do

- An exception drops a whole **row**. When a row lists several resources in a column (`source_parents`, `model_parents`, `leaf_children`, `model_children`), accepting one of them accepts the row, even if the other elements would still be a violation by themselves.
- Patterns are matched per check, on the columns of that check only, and are case-sensitive.
- `fct_documentation_coverage` and `fct_test_coverage` are measures of the whole project, not lists of resources, so they ignore the exceptions. To remove resources from them, use `exclude_packages` or `exclude_paths_from_project`.
- Hard coded references are reported by `dbt lint`, not by a check, so there is nothing to configure here.

## Other ways to ignore results

Exceptions apply to a single check. The other options below apply to more:

| You want to... | Use |
| -------------- | --- |
| accept some violations of a given rule | the [exceptions](#accepting-violations-of-a-check) above |
| accept the violations of resources that declare it in their config (for example in their `meta`) | [the SQL condition](#in-the-config-of-the-resources) |
| stop evaluating a rule entirely | [disable the check](customization.md) |
| keep a rule but not block the build when it is violated | keep its severity at `warn` (the default), see [running as a CI check](../ci-check.md) |
| ignore a package, a folder or some models/sources for **all** the rules | [`exclude_packages` and `exclude_paths_from_project`](excluding-packages-and-paths.md) |
| ignore some resources for a given run or job | `--exclude` or `--selector`, see below |

## Ignoring resources in a given run

The rows reported by a check are restricted to the resources selected by `--select` and `--exclude`, because each check returns the resource to fix in the column `unique_id`:

```bash
# all the checks, except for the models in the legacy folder
dbt check --exclude path:models/legacy

# a single check, without the models called stg_<...>_unioned
dbt check fct_multiple_sources_joined --exclude "stg_*_unioned"
```

To make it permanent, define the selection in a YAML [selector](https://docs.getdbt.com/reference/node-selection/yaml-selectors) and use it with `--selector`:

```yaml title="selectors.yml"
selectors:
  - name: evaluated_resources
    definition:
      method: fqn
      value: "*"
      exclude:
        - method: path
          value: models/legacy
```

```bash
dbt check --selector evaluated_resources
```

!!! note

    `fct_documentation_coverage` and `fct_test_coverage` always evaluate the whole project (`selection_filter_on: none`). To exclude resources from those two checks, use `exclude_packages` or `exclude_paths_from_project`.
