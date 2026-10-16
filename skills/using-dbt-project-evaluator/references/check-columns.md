# Columns of each check (for exceptions)

Every check except `fct_documentation_coverage` and `fct_test_coverage` returns `unique_id` (the resource to fix) plus the columns below. An exception can match the resource (`- stg_legacy_%`) or any of these columns (`- {parent: stg_base_%}`); a column holding a list (`source_parents`, `model_parents`, `leaf_children`, `model_children`) matches when any element does. The two coverage checks measure the whole project: they ignore `--select` and exceptions, and report only when the coverage is below its target.

| Check | Columns (and what to filter on in an exception) |
| ----- | ----------------------------------------------- |
| `fct_documentation_coverage` | (project-wide metric: no exceptions) |
| `fct_undocumented_models` | `name`, `original_file_path` |
| `fct_undocumented_source_tables` | `source_name`, `original_file_path` |
| `fct_undocumented_sources` | `source_name`, `original_file_path` |
| `fct_exposures_dependent_on_private_models` | `exposure_name`, `parent_unique_id`, `parent_resource_name`, `parent_resource_type`, `parent_access` — `exposure_name` and `parent_resource_name` are the two ends |
| `fct_public_models_without_contract` | `name`, `access`, `contract_enforced` |
| `fct_undocumented_public_models` | `name`, `is_described_model`, `total_defined_columns`, `total_described_columns` |
| `fct_direct_join_to_source` | `name`, `source_parents`, `model_parents` — `name` is the model that reads from both; the parents are lists of names |
| `fct_duplicate_sources` | `source_name`, `source_relation` — `source_relation` is the table that several sources point at |
| `fct_marts_or_intermediate_dependent_on_source` | `name`, `model_type`, `source_name` — `name` is the model, `source_name` the source it reads from |
| `fct_model_fanout` | `name`, `leaf_children` — `name` is the model with the fanout, `leaf_children` a list of names |
| `fct_multiple_sources_joined` | `name`, `source_parents` — `name` is the model, `source_parents` a list of source names |
| `fct_rejoining_of_upstream_concepts` | `parent`, `parent_and_child`, `child` — `parent` is the model with two paths to `child`, `parent_and_child` the model in between |
| `fct_root_models` | `name`, `original_file_path` |
| `fct_source_fanout` | `source_name`, `model_children` — `source_name` is the source, `model_children` a list of names |
| `fct_staging_dependent_on_marts_or_intermediate` | `name`, `parent`, `parent_model_type` — `name` is the staging model, `parent` the model it reads from |
| `fct_staging_dependent_on_staging` | `name`, `parent` — `name` is the staging model, `parent` the staging model it reads from |
| `fct_too_many_joins` | `name`, `parent_count` |
| `fct_unused_sources` | `source_name`, `original_file_path` |
| `fct_chained_views_dependencies` | `child`, `parent`, `distance` — `child` is the model at the end of the chain, `parent` the first view of the chain |
| `fct_exposure_parents_materializations` | `exposure_name`, `parent_resource_type`, `parent_resource_name`, `parent_model_materialization` — `exposure_name` and `parent_resource_name` are the two ends |
| `fct_model_directories` | `name`, `model_type`, `current_file_path`, `change_file_path_to` |
| `fct_model_naming_conventions` | `name`, `model_type`, `appropriate_prefixes`, `original_file_path` |
| `fct_source_directories` | `source_name`, `current_file_path`, `change_file_path_to` |
| `fct_test_directories` | `model_name`, `current_properties_yml_file_path`, `change_properties_yml_directory_to` |
| `fct_missing_primary_key_tests` | `name`, `resource_type` |
| `fct_sources_without_freshness` | `source_name` |
| `fct_test_coverage` | (project-wide metric: no exceptions) |
