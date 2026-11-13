# The checks, what they flag and how to fix them

One row per check. The category is also the folder and the tag of the check (`dbt ls --resource-type check --select tag:modeling`). Recipes with snippets: [playbooks.md](playbooks.md). Rule explanations: `dbt_packages/dbt_project_evaluator/docs/rules/<category>.md`.

**Risk**: *Safe, additive* changes no SQL and no relation name. *Structure* changes paths or names that other files refer to. *Needs judgement* changes the DAG or the cost: show the plan to the user first.

| Check | Category | What it flags | Usual fix | Risk |
| ----- | -------- | ------------- | --------- | ---- |
| `fct_documentation_coverage` | documentation | Project-wide: the share of documented models is below `documentation_coverage_target`. Always evaluates the whole project. | Raise it by fixing `fct_undocumented_models` and `fct_undocumented_public_models`. | Safe, additive |
| `fct_undocumented_models` | documentation | Models without a description. | Add a description (model YAML or a docs block). | Safe, additive |
| `fct_undocumented_source_tables` | documentation | Source tables without a description. | Add a description to the table. | Safe, additive |
| `fct_undocumented_sources` | documentation | Sources (the top-level `sources:` entry) without a description. One row per source (`unique_id` is one of its tables). | Add a description to the source. | Safe, additive |
| `fct_exposures_dependent_on_private_models` | governance | Exposures whose direct parents are anything other than public models. | Set `access: public` on the models the exposure depends on, with a contract and documentation. | Needs judgement (changes who may ref the model) |
| `fct_public_models_without_contract` | governance | Public models without an enforced contract. | Enforce the contract: `data_type` for every column. | Safe, additive (can fail the build if types differ) |
| `fct_undocumented_public_models` | governance | Public models missing a description, or with undocumented (or no) columns. | Describe the model and every column. | Safe, additive |
| `fct_direct_join_to_source` | modeling | Models that select from both a source and another model. Add a staging model for the source and select from that instead. | Create a staging model for the source and select from it. | Needs judgement (new model, refs change) |
| `fct_duplicate_sources` | modeling | More than one source node points at the same database object. Keep a single source definition per table. | Keep one source definition per table and re-point the refs. | Needs judgement |
| `fct_marts_or_intermediate_dependent_on_source` | modeling | Marts or intermediate models that select directly from a source. Go through a staging model. | Select from the staging model of the source instead. | Needs judgement |
| `fct_model_fanout` | modeling | Models with at least `models_fanout_threshold` direct leaf children. Consider moving shared logic upstream or into a BI layer. | Move shared logic upstream, or build the leaves in the BI layer. | Needs judgement |
| `fct_multiple_sources_joined` | modeling | Models that select from more than one source. Give each source its own staging model and join downstream. | One staging model per source, join downstream. | Needs judgement |
| `fct_rejoining_of_upstream_concepts` | modeling | A -> B -> C where C also selects from A and B is only used by C. unique_id is B, which can usually be folded into C. | Fold the model in between into its only child. | Needs judgement |
| `fct_root_models` | modeling | Models with no parents, which usually means a hard-coded table reference instead of source() or ref(). | Replace the hard-coded table with `source()` or `ref()`. | Needs judgement (may be intentional) |
| `fct_source_fanout` | modeling | Sources selected from by more than one model. A source should feed exactly one staging model. | One staging model per source table; everything else selects from it. | Needs judgement |
| `fct_staging_dependent_on_marts_or_intermediate` | modeling | Staging models that select from marts or intermediate models. | Select from sources through staging, move the logic downstream. | Needs judgement |
| `fct_staging_dependent_on_staging` | modeling | Staging models that select from other staging models. Use a base model or move the logic downstream. | Use a `base_` model, or move the logic to an intermediate model. | Needs judgement |
| `fct_too_many_joins` | modeling | Models with at least `too_many_joins_threshold` direct parents. Consider breaking them into intermediate models. | Split into intermediate models; do not raise the threshold. | Needs judgement |
| `fct_unused_sources` | modeling | Sources that nothing selects from. Remove them or build the staging model that should use them. | Remove the source table, or build the staging model that should use it. | Needs judgement (ask why it is there) |
| `fct_chained_views_dependencies` | performance | Models at the end of a chain of more than `chained_views_threshold` views or ephemeral models. Materialize something in the chain as a table. | Materialize a well-used model of the chain as a table or incremental. | Needs judgement (cost, freshness) |
| `fct_exposure_parents_materializations` | performance | Exposures fed directly by a source, or by a view or ephemeral model, instead of a table. | Materialize the parent as table or incremental; replace a source parent by a model. | Needs judgement (cost) |
| `fct_model_directories` | structure | Models outside the directory their model type calls for; staging models must sit in a directory named after their source. | Move the file to `change_file_path_to`. | Structure (paths change) |
| `fct_model_naming_conventions` | structure | Models whose name does not start with any prefix configured for their model type (`<model_type>_prefixes`). | Rename with a prefix from `appropriate_prefixes`; update refs, YAML, exposures. | Structure (name changes) |
| `fct_source_directories` | structure | Source YAML that is not in a directory named after the source. | Move the source YAML to `change_file_path_to`. | Structure (paths change) |
| `fct_test_directories` | structure | Tested models whose properties YAML (where their tests are defined) lives outside the model directory. | Move the tests of the model into a YAML in the model's directory. | Structure (paths change) |
| `fct_missing_primary_key_tests` | testing | Resources (of `enforced_primary_key_node_types`) without a column that carries one full set of `primary_key_test_macros`. | Add `unique` and `not_null` on the grain (or a combination-of-columns test). | Safe, additive (needs the grain) |
| `fct_sources_without_freshness` | testing | Source tables with neither a warn_after nor an error_after freshness threshold. | Add `freshness` and `loaded_at_field` to the source. | Safe, additive (needs the loaded-at column) |
| `fct_test_coverage` | testing | Project-wide: the share of models with at least one test is below `test_coverage_target`. A test covers the node it is declared on. Always evaluates the whole project. | Raise it by testing models: see `fct_missing_primary_key_tests`. | Safe, additive |
