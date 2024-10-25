---
hide:
  - toc
---

# List of the rules currently defined

|Type                                          |Friendly name                                                                                                        |fact name    |
|----------------------------------------------|---------------------------------------------------------------------------------------------------------------------|-------------|
|Modeling                                      |[Staging Models Dependent on Other Staging Models](../rules/modeling/#staging-models-dependent-on-other-staging-models)|`fct_staging_dependent_on_staging`|
|Modeling                                      |[Source Fanout](../rules/modeling/#source-fanout)                                                                      |`fct_source_fanout`|
|Modeling                                      |[Rejoining of Upstream Concepts](../rules/modeling/#rejoining-of-upstream-concepts)                                    |`fct_rejoining_of_upstream_concepts`|
|Modeling                                      |[Model Fanout](../rules/modeling/#model-fanout)                                                                        |`fct_model_fanout`|
|Modeling                                      |[Downstream Models Dependent on Source](../rules/modeling/#downstream-models-dependent-on-source)                      |`fct_marts_or_intermediate_dependent_on_source`|
|Modeling                                      |[Direct Join to Source](../rules/modeling/#direct-join-to-source)                                                      |`fct_direct_join_to_source`|
|Modeling                                      |[Duplicate Sources](../rules/modeling/#duplicate-sources)                                                              |`fct_duplicate_sources`|
|Modeling                                      |[Hard Coded References](../rules/modeling/#hard-coded-references)                                                      |`fct_hard_coded_references`|
|Modeling                                      |[Multiple Sources Joined](../rules/modeling/#multiple-sources-joined)                                                  |`fct_multiple_sources_joined`|
|Modeling                                      |[Root Models](../rules/modeling/#root-models)                                                                          |`fct_root_models`|
|Modeling                                      |[Staging Models Dependent on Downstream Models](../rules/modeling/#staging-models-dependent-on-downstream-models)      |`fct_staging_dependent_on_marts_or_intermediate`|
|Modeling                                      |[Unused Sources](../rules/modeling/#unused-sources)                                                                    |`fct_unused_sources`|
|Modeling                                      |[Models with Too Many Joins](../rules/modeling/#models-with-too-many-joins)                                            |`fct_too_many_joins`|
|Testing                                       |[Missing Primary Key Tests](../rules/testing/#missing-primary-key-tests)                                               |`fct_missing_primary_key_tests`|
|Testing                                       |[Missing Source Freshness](../rules/testing/#missing-source-freshness)                                                 |`fct_sources_without_freshness`|
|Testing                                       |[Test Coverage](../rules/testing/#test-coverage)                                                                       |`fct_test_coverage`|
|Documentation                                 |[Undocumented Models](../rules/documentation/#undocumented-models)                                                     |`fct_undocumented_models`|
|Documentation                                 |[Documentation Coverage](../rules/documentation/#documentation-coverage)                                               |`fct_documentation_coverage`|
|Documentation                                 |[Undocumented Source Tables](../rules/documentation/#undocumented-source-tables)                                       |`fct_undocumented_source_tables`|
|Documentation                                 |[Undocumented Sources](../rules/documentation/#undocumented-sources)                                                   |`fct_undocumented_sources`|
|Structure                                     |[Test Directories](../rules/structure/#test-directories)                                                               |`fct_test_directories`|
|Structure                                     |[Model Naming Conventions](../rules/structure/#model-naming-conventions)                                               |`fct_model_naming_conventions`|
|Structure                                     |[Source Directories](../rules/structure/#source-directories)                                                           |`fct_source_directories`|
|Structure                                     |[Model Directories](../rules/structure/#model-directories)                                                             |`fct_model_directories`|
|Performance                                   |[Chained View Dependencies](../rules/performance/#chained-view-dependencies)                                           |`fct_chained_views_dependencies`|
|Performance                                   |[Exposure Parents Materializations](../rules/performance/#exposure-parents-materializations)                           |`fct_exposure_parents_materializations`|
|Governance                                    |[Public Models Without Contracts](../rules/governance/#public-models-without-contracts)                                |`fct_public_models_without_contracts`|
|Governance                                    |[Exposures Dependent on Private Models](../rules/governance/#exposures-dependent-on-private-models)                    |`fct_exposures_dependent_on_private_models`|
|Governance                                    |[Undocumented Public Models](../rules/governance/#undocumented-public-models)                                          |`fct_undocumented_public_models`|
