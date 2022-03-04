This package is used to flag areas within a dbt project that are misaligned with dbt Labs' best practices.

# Contributing
If you'd like to add models to flag new areas, please update this README and add an integration test ([more details here](https://github.com/dbt-labs/pro-serv-dag-auditing/tree/main/integration_tests#adding-an-integration-test)).

# Contents

__[Documentation Coverage](#documentation-coverage)__

__[Test Coverage](#test-coverage)__

__[DAG Issues](#dag-issues)__
- [Direct Join to Source](#direct-join-to-source)
- [Model Fanout](#model-fanout)
- [Multiple Sources Joined](#multiple-sources-joined)
- [Rejoining of Upstream Concepts](#rejoining-of-upstream-concepts)
- [Root Models](#root-models)
- [Source Fanout](#source-fanout)
- [Unused Sources](#unused-sources)

## Documentation Coverage

## Test Coverage

###

`fct_untested_models` lists every model with no tests.
`fct_test_coverage` contains metrics pertaining to project-wide test coverage.

[At a minimum](https://www.getdbt.com/analytics-engineering/transformation/data-testing/#what-should-you-test), every model should have `not_null` and `unique` tests set up on a primary key.

## DAG Issues

### Direct Join to Source
__Model__

`fct_direct_join_to_source` shows each parent/child relationship where a model has a reference to both a model and a source.

__Reason For Flag__

__How to Remediate__

__Example__

`model_2` is pulling in both a model and a source.
<p align = "center">
<img width="800" alt="DAG showing a model and a source joining into a new model" src="https://user-images.githubusercontent.com/91074396/156454034-1f516133-ae52-48d6-9204-2358441ebb44.png">

### Model Fanout
__Model__

`fct_model_fanout` shows all parents with more direct leaf children than the threshold for fanout (determined by variable models_fanout_threshold, default 3)

__Reason For Flag__

__How to Remediate__

__Example__

`fct_model` has three direct leaf children.
<p align = "center">
<img width="800" alt="A DAG showing three models branching out of a fct model" src="https://user-images.githubusercontent.com/91074396/156635853-99bd1bea-662a-4247-875d-cd7cf33c6ac1.png">

### Multiple Sources Joined
__Model__

`fct_multiple_sources_joined` shows each parent/child relationship where a model references more than one source.

__Reason For Flag__

__How to Remediate__

__Example__

`model_1` references two source tables.
<p align = "center">
<img width="800" alt="A DAG showing two source nodes feeding into a model" src="https://user-images.githubusercontent.com/91074396/156641049-74bd9168-e012-4d77-b343-bfde16cad0d3.png">

### Rejoining of Upstream Concepts

__Model__

`fct_rejoining_of_upstream_concepts` shows all cases where one of the parent node's direct children (child) is _also_ the direct child of _another_ one of the parent node's direct children (parent_and_child). Only includes cases where the model "in between" the parent node and child node has NO other downstream dependencies.

__Reason For Flag__

__How to Remediate__

__Example__

`stg_model`, `int_model`, and `fct_model` create a "loop" in the DAG. `int_model` has no other downstream dependencies other than `fct_model`.
<p align = "center">
<img width="800" alt="A DAG showing four nodes. A source is feeding into a staging model. The staging model is referenced by both an int model and a fct model. The int model is also being referenced by the fct model. This creates a 'loop' between the staging model, the int model, and the fct model." src="https://user-images.githubusercontent.com/91074396/156642410-d402a7c0-bf91-4b9a-8b3c-815aa7cbbccb.png">

### Root Models
__Model__

`fct_root_models` shows each model with 0 direct parents.

__Reason For Flag__

__How to Remediate__

__Example__

`model_4` has no direct parents
<p align = "center">
<img width="800" alt="A DAG showing three source tables, each being referenced by a staging model. Each staging model is being referenced by another accompanying model. model_4 is an independent node not being referenced by any models " src="https://user-images.githubusercontent.com/91074396/156644411-83e269e7-f1f9-4f46-9cfd-bdee1c8e6b22.png">

### Source Fanout
__Model__

`fct_source_fanout` shows each parent/child relationship where a source is the direct parent of multiple nodes in the DAG.

__Reason For Flag__

__How to Remediate__

__Example__

`source.table_1` has more than one direct child model.
<p align = "center">
<img width="800" alt="" src="https://user-images.githubusercontent.com/91074396/156636403-3bcfdbc3-cf48-4c8f-98dc-addc274ad321.png">

### Unused Sources
__Model__

`fct_unused_sources` shows each source with 0 children.

__Reason For Flag__

__How to Remediate__

__Example__

`source.table_4` isn't being referenced.
<p align = "center">
<img width="800" alt="A DAG showing three sources which are each being referenced by an accompanying staging model, and one source that isn't being referenced at all" src="https://user-images.githubusercontent.com/91074396/156637881-f67c1a28-93c7-4a91-9337-465aad94b73a.png">
