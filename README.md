This project is intended to be a dbt proect with poor DAG modeling so the professional services team can develop tools to detect these errors

## Types of DAG Issues

- [Direct Join to Source](#direct-join-to-source)
- [Model Fanout](#model-fanout)
- [Multiple Sources Joined](#multiple-sources-joined)
- [Rejoining of Upstream Concepts](#rejoining-of-upstream-concepts)
- [Root Models](#root-models)
- [Source Fanout](#source-fanout)
- [Unused Sources](#unused-sources)

### Direct Join to Source
__Model__: fct_direct_join_to_source

This table shows each parent/child relationship where a model has a reference to both a model and a source.

### Model Fanout
__Model__: fct_model_fanout

This table shows all parents with more direct leaf children than the threshold for fanout (determined by variable models_fanout_threshold, default 3)

### Multiple Sources Joined
__Model__: fct_multiple_sources_joined

This table shows each parent/child relationship where a model references more than one source.

### Rejoining of Upstream Concepts
__Model__: fct_rejoining_of_upstream_concepts

All cases where one of the parent node's direct children (child) is ALSO the direct child of ANOTHER one of the parent node's direct children (parent_and_child). Only includes cases where the model "in between" the parent node and child node has NO other downstream dependencies.

### Root Models
__Model__: fct_root_models

This table shows each model with 0 direct parents.

### Source Fanout
__Model__: fct_source_fanout

This table shows each parent/child relationship where a source is the direct parent of multiple nodes in the DAG.

### Unused Sources
__Model__: fct_unused_sources

This table shows each source with 0 children.


![image](https://user-images.githubusercontent.com/53586774/157129634-98263607-7538-4b66-b424-4eaf9b34d58f.png)


### Limitation with BigQuery

BigQuery current support for recursive CTEs is limited. 

For BigQuery, the model `int_all_dag_relationships` needs to be created by looping CTEs instead. The number of loops is defaulted to 9, which means that dependencies between models of more than 9 levels of separation won't show in the model `int_all_dag_relationships` but tests on the DAG will still be correct. With a number of loops higher than 9 BigQuery sometimes raises an error saying the query is too complex.
