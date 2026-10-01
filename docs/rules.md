---
hide:
  - toc
---

# List of the rules currently defined

Each rule is a [native dbt check](https://docs.getdbt.com/docs/build/checks) with the name listed in the last column. Use it to [run](index.md#how-it-works), [configure](customization/customization.md) or [select](customization/exceptions.md) a given rule, for example with `dbt check fct_root_models`. The checks are tagged with their type, for example `dbt ls --resource-type check --select tag:modeling`.

|Type                                          |Friendly name                                                                                                        |check name   |
|----------------------------------------------|---------------------------------------------------------------------------------------------------------------------|-------------|
|Modeling                                      |[Staging Models Dependent on Other Staging Models](rules/modeling.md#staging-models-dependent-on-other-staging-models)|`fct_staging_dependent_on_staging`|
|Modeling                                      |[Source Fanout](rules/modeling.md#source-fanout)                                                                      |`fct_source_fanout`|
|Modeling                                      |[Rejoining of Upstream Concepts](rules/modeling.md#rejoining-of-upstream-concepts)                                    |`fct_rejoining_of_upstream_concepts`|
|Modeling                                      |[Model Fanout](rules/modeling.md#model-fanout)                                                                        |`fct_model_fanout`|
|Modeling                                      |[Downstream Models Dependent on Source](rules/modeling.md#downstream-models-dependent-on-source)                      |`fct_marts_or_intermediate_dependent_on_source`|
|Modeling                                      |[Direct Join to Source](rules/modeling.md#direct-join-to-source)                                                      |`fct_direct_join_to_source`|
|Modeling                                      |[Duplicate Sources](rules/modeling.md#duplicate-sources)                                                              |`fct_duplicate_sources`|
|Modeling                                      |[Hard Coded References](rules/modeling.md#hard-coded-references)                                                      |`fct_hard_coded_references` (removed in version 2, see [differences from 1.x](index.md#differences-from-1x))|
|Modeling                                      |[Multiple Sources Joined](rules/modeling.md#multiple-sources-joined)                                                  |`fct_multiple_sources_joined`|
|Modeling                                      |[Root Models](rules/modeling.md#root-models)                                                                          |`fct_root_models`|
|Modeling                                      |[Staging Models Dependent on Downstream Models](rules/modeling.md#staging-models-dependent-on-downstream-models)      |`fct_staging_dependent_on_marts_or_intermediate`|
|Modeling                                      |[Unused Sources](rules/modeling.md#unused-sources)                                                                    |`fct_unused_sources`|
|Modeling                                      |[Models with Too Many Joins](rules/modeling.md#models-with-too-many-joins)                                            |`fct_too_many_joins`|
|Testing                                       |[Missing Primary Key Tests](rules/testing.md#missing-primary-key-tests)                                               |`fct_missing_primary_key_tests`|
|Testing                                       |[Missing Source Freshness](rules/testing.md#missing-source-freshness)                                                 |`fct_sources_without_freshness`|
|Testing                                       |[Test Coverage](rules/testing.md#test-coverage)                                                                       |`fct_test_coverage`|
|Documentation                                 |[Undocumented Models](rules/documentation.md#undocumented-models)                                                     |`fct_undocumented_models`|
|Documentation                                 |[Documentation Coverage](rules/documentation.md#documentation-coverage)                                               |`fct_documentation_coverage`|
|Documentation                                 |[Undocumented Source Tables](rules/documentation.md#undocumented-source-tables)                                       |`fct_undocumented_source_tables`|
|Documentation                                 |[Undocumented Sources](rules/documentation.md#undocumented-sources)                                                   |`fct_undocumented_sources`|
|Structure                                     |[Test Directories](rules/structure.md#test-directories)                                                               |`fct_test_directories`|
|Structure                                     |[Model Naming Conventions](rules/structure.md#model-naming-conventions)                                               |`fct_model_naming_conventions`|
|Structure                                     |[Source Directories](rules/structure.md#source-directories)                                                           |`fct_source_directories`|
|Structure                                     |[Model Directories](rules/structure.md#model-directories)                                                             |`fct_model_directories`|
|Performance                                   |[Chained View Dependencies](rules/performance.md#chained-view-dependencies)                                           |`fct_chained_views_dependencies`|
|Performance                                   |[Exposure Parents Materializations](rules/performance.md#exposure-parents-materializations)                           |`fct_exposure_parents_materializations`|
|Governance                                    |[Public Models Without Contracts](rules/governance.md#public-models-without-contracts)                                |`fct_public_models_without_contract`|
|Governance                                    |[Exposures Dependent on Private Models](rules/governance.md#exposures-dependent-on-private-models)                    |`fct_exposures_dependent_on_private_models`|
|Governance                                    |[Undocumented Public Models](rules/governance.md#undocumented-public-models)                                          |`fct_undocumented_public_models`|
