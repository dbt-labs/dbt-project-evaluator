# The checks of dbt_project_evaluator

One row per check. Every check except `fct_documentation_coverage` and `fct_test_coverage` returns `unique_id` (the resource to fix) plus the columns listed. The two coverage checks measure the whole project: they ignore `--select` and exceptions, and report only when the coverage is below its target.

Explanations and remediation for each rule: `dbt_packages/dbt_project_evaluator/docs/rules/<category>.md` (categories: modeling, testing, documentation, structure, performance, governance), also published at https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/.

| Check | Category | What it flags and the usual fix | Columns (and what to filter on in an exception) |
| ----- | -------- | ------------------------------- | ----------------------------------------------- |
| `fct_documentation_coverage` | documentation | Project-wide: the share of documented models is below `documentation_coverage_target`. Always evaluates the whole project. | (project-wide metric: no exceptions) |
| `fct_undocumented_models` | documentation | Models without a description. | `name`, `original_file_path` |
| `fct_undocumented_source_tables` | documentation | Source tables without a description. | `source_name`, `original_file_path` |
| `fct_undocumented_sources` | documentation | Sources (the top-level `sources:` entry) without a description. One row per source (`unique_id` is one of its tables). | `source_name`, `original_file_path` |
| `fct_exposures_dependent_on_private_models` | governance | Exposures whose direct parents are anything other than public models. | `exposure_name`, `parent_unique_id`, `parent_resource_name`, `parent_resource_type`, `parent_access` — `exposure_name` and `parent_resource_name` are the two ends |
| `fct_public_models_without_contract` | governance | Public models without an enforced contract. | `name`, `access`, `contract_enforced` |
| `fct_undocumented_public_models` | governance | Public models missing a description, or with undocumented (or no) columns. | `name`, `is_described_model`, `total_defined_columns`, `total_described_columns` |
| `fct_direct_join_to_source` | modeling | Models that select from both a source and another model. Add a staging model for the source and select from that instead. | `name`, `source_parents`, `model_parents` — `name` is the model that reads from both; the parents are lists of names |
| `fct_duplicate_sources` | modeling | More than one source node points at the same database object. Keep a single source definition per table. | `source_name`, `source_relation` — `source_relation` is the table that several sources point at |
| `fct_marts_or_intermediate_dependent_on_source` | modeling | Marts or intermediate models that select directly from a source. Go through a staging model. | `name`, `model_type`, `source_name` — `name` is the model, `source_name` the source it reads from |
| `fct_model_fanout` | modeling | Models with at least `models_fanout_threshold` direct leaf children. Consider moving shared logic upstream or into a BI layer. | `name`, `leaf_children` — `name` is the model with the fanout, `leaf_children` a list of names |
| `fct_multiple_sources_joined` | modeling | Models that select from more than one source. Give each source its own staging model and join downstream. | `name`, `source_parents` — `name` is the model, `source_parents` a list of source names |
| `fct_rejoining_of_upstream_concepts` | modeling | A -> B -> C where C also selects from A and B is only used by C. unique_id is B, which can usually be folded into C. | `parent`, `parent_and_child`, `child` — `parent` is the model with two paths to `child`, `parent_and_child` the model in between |
| `fct_root_models` | modeling | Models with no parents, which usually means a hard-coded table reference instead of source() or ref(). | `name`, `original_file_path` |
| `fct_source_fanout` | modeling | Sources selected from by more than one model. A source should feed exactly one staging model. | `source_name`, `model_children` — `source_name` is the source, `model_children` a list of names |
| `fct_staging_dependent_on_marts_or_intermediate` | modeling | Staging models that select from marts or intermediate models. | `name`, `parent`, `parent_model_type` — `name` is the staging model, `parent` the model it reads from |
| `fct_staging_dependent_on_staging` | modeling | Staging models that select from other staging models. Use a base model or move the logic downstream. | `name`, `parent` — `name` is the staging model, `parent` the staging model it reads from |
| `fct_too_many_joins` | modeling | Models with at least `too_many_joins_threshold` direct parents. Consider breaking them into intermediate models. | `name`, `parent_count` |
| `fct_unused_sources` | modeling | Sources that nothing selects from. Remove them or build the staging model that should use them. | `source_name`, `original_file_path` |
| `fct_chained_views_dependencies` | performance | Models at the end of a chain of more than `chained_views_threshold` views or ephemeral models. Materialize something in the chain as a table. | `child`, `parent`, `distance` — `child` is the model at the end of the chain, `parent` the first view of the chain |
| `fct_exposure_parents_materializations` | performance | Exposures fed directly by a source, or by a view or ephemeral model, instead of a table. | `exposure_name`, `parent_resource_type`, `parent_resource_name`, `parent_model_materialization` — `exposure_name` and `parent_resource_name` are the two ends |
| `fct_model_directories` | structure | Models outside the directory their model type calls for; staging models must sit in a directory named after their source. | `name`, `model_type`, `current_file_path`, `change_file_path_to` |
| `fct_model_naming_conventions` | structure | Models whose name does not start with any prefix configured for their model type (`<model_type>_prefixes`). | `name`, `model_type`, `appropriate_prefixes`, `original_file_path` |
| `fct_source_directories` | structure | Source YAML that is not in a directory named after the source. | `source_name`, `current_file_path`, `change_file_path_to` |
| `fct_test_directories` | structure | Tested models whose properties YAML (where their tests are defined) lives outside the model directory. | `model_name`, `current_properties_yml_file_path`, `change_properties_yml_directory_to` |
| `fct_missing_primary_key_tests` | testing | Resources (of `enforced_primary_key_node_types`) without a column that carries one full set of `primary_key_test_macros`. | `name`, `resource_type` |
| `fct_sources_without_freshness` | testing | Source tables with neither a warn_after nor an error_after freshness threshold. | `source_name` |
| `fct_test_coverage` | testing | Project-wide: the share of models with at least one test is below `test_coverage_target`. A test covers the node it is declared on. Always evaluates the whole project. | (project-wide metric: no exceptions) |
