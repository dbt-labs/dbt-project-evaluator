This package is used to flag areas within a dbt project that are misaligned with dbt Labs' best practices.

# Contributing
If you'd like to add models to flag new areas, please update this README and add an integration test 
([more details here](https://github.com/dbt-labs/pro-serv-dag-auditing/tree/main/integration_tests#adding-an-integration-test)).

# Usage

## Disabling models

If there is a particular model or set of models that you *do not want this package to execute*, you can 
disable these models as you would any other model in your `dbt_project.yml` file

```yml
# dbt_project.yml

models:
  dbt_project_evaluator:
    tests:
      # disable entire test coverage suite
      +enabled: false
    dag:
      # disable single DAG model
      fct_model_fanout:
        +enabled: false

```

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

`fct_undocumented_models` lists every model with no description configured.

`fct_documentation_coverage` calculates the percent of enabled models in the project that have 
a configured description.

Tip: We recommend you add descriptions to at least 75 percent of your models.

## Test Coverage

`fct_untested_models` lists every model with no tests.

`fct_test_coverage` contains metrics pertaining to project-wide test coverage.

Tip: We recommend [at a minimum](https://www.getdbt.com/analytics-engineering/transformation/data-testing/#what-should-you-test), every model should have `not_null` and `unique` tests set up on a primary key.

## DAG Issues

### Bending Connections
###### Model

`fct_bending_connections` shows each parent/child relationship where models in the staging layer are 
dependent on each other.

###### Graph Example

`stg_model_1` is a parent of `stg_model_2`
<p align = "center">
<img width="800" alt="A DAG showing stg_model_1 as a parent of stg_model_2 and int_model" src="https://user-images.githubusercontent.com/91074396/157698052-06654cb2-6a8d-45f8-a29a-7154d73edf59.png">

###### Reason to Flag

###### How to Remediate



### Direct Join to Source
###### Model

`fct_direct_join_to_source` shows each parent/child relationship where a model has a reference to 
both a model and a source.

###### Graph Example

`model_2` is pulling in both a model and a source.
<p align = "center">
<img width="800" alt="DAG showing a model and a source joining into a new model" src="https://user-images.githubusercontent.com/91074396/156454034-1f516133-ae52-48d6-9204-2358441ebb44.png">
  
###### Reason to Flag

###### How to Remediate


### Model Fanout
###### Model

`fct_model_fanout` shows all parents with more direct leaf children than the threshold for fanout 
(determined by variable models_fanout_threshold, default 3)
  
###### Graph Example

`fct_model` has three direct leaf children.
<p align = "center">
<img width="800" alt="A DAG showing three models branching out of a fct model" src="https://user-images.githubusercontent.com/30663534/159601497-c141c5ba-d3a6-465a-ab8f-12056d28c5ee.png">

###### Reason to Flag

This might indicate some transformations should move to the BI layer, or a common business transformations
should be moved upstream.

###### Exceptions

Some BI tools are better than others at joining and data exploration. For example, with Looker you could 
end your DAG after marts (i.e. fcts & dims) and join those artifacts together (with a little know how 
and setup time) to make your reports. For others, like Tableau, model fanouts might be more 
beneficial, as this tool prefers big tables over joins, so predefining some reports is usually more performant. 
  
###### How to Remediate

Queries and transformations can move around between dbt and the BI tool, so how do we try to stay 
effortful in what we decide to put where? 

You can think of dbt as our assembly line which produces expected outputs every time.

You can think of the BI layer as the place where we take the items produced from our assembly line to 
customize them in order to meet our stakeholder's needs.

<!---
TODO: edit this line in 6 months after more progress is made on the metrics server
-->
Your dbt project needs a defined end point! Until the metrics server comes to fruition, you cannot possibly
predefine every query or quandary your team might have. So decide as a team where that line is and maintain it.

### Multiple Sources Joined
###### Model

`fct_multiple_sources_joined` shows each parent/child relationship where a model references more than one source.

###### Graph Example

`model_1` references two source tables.
<p align = "center">
<img width="800" alt="A DAG showing two sources feeding into a staging model" src="https://user-images.githubusercontent.com/30663534/159605226-14b23d28-1b30-42c9-85a9-3fbe5a41c025.png"> 
  
###### Reason to Flag

We very strongly believe that a staging model is the atomic unit of data modeling. Each staging 
model bears a one-to-one relationship with the source data table it represents. It has the same 
granularity, but the columns have been renamed, recast, or usefully reconsidered into a consistent 
format. With that in mind, two `{{ source() }}` declarations in one staging model likely means we are 
not being composable enough and there are individual building blocks which could be broken out into
their respective models. 

###### Exceptions
  
NoSQL databases or heavily nested data sources often have so much info json packed into a table 
that you need to break one raw data source into multiple base models.

Also, sometimes companies will have a bunch of [identical sources across systems](https://discourse.getdbt.com/t/unioning-identically-structured-data-sources/921) and you union them once before you stage them.

These make total sense, and you should keep them in your project. To continue to test your project, you can 
count those instances, then add a [warn_if](https://docs.getdbt.com/reference/resource-configs/severity) 
threshold to the test to account for the known examples.
  
###### How to Remediate

In this example specifically, those raw sources, `source_1.table_1` and `source_1.table_2` should each 
have their own staging model (`stg_model_1` and `stg_model_2`), as transitional steps, which will 
then be combined into a new `int_model_2`. Alternatively, you could keep `stg_model_2` and add 
`base__` models as transitional steps.

To fix this, try out the [codegen](https://hub.getdbt.com/dbt-labs/codegen/latest/) package! With 
this package you can dynamically generate the SQL for a staging (what they call base) model, which 
you will use to populate `stg_model_1` and `stg_model_2` directly from the source data. Create a 
new model `int_model_2`. Afterwards, within `int_model_2`, update your `{{ source() }}` macros to 
`{{ ref() }}` macros and point them to your newly built staging models. If you had type casting, 
field aliasing, or other simple improvements made in your original `stg_model_2` SQL, then attempt 
to move that logic back to the new staging models instead. This will help colocate those 
transformations and avoid duplicate code, so that all downstream models can leverage the same 
set of transformations.

Post-refactor, your DAG should look like this:
  <p align = "center">
  <img width="800" alt="A refactored DAG showing two staging models feeding into an intermediate model" src="https://user-images.githubusercontent.com/30663534/159601894-3997eb34-32c2-4a80-a617-537ee96a8cf3.png">

  or if you want to use base_ models and keep stg_model_2 as is:
  <p align = "center">
  <img width="800" alt="A refactored DAG showing two base models feeding into a staging model" src="https://user-images.githubusercontent.com/30663534/159602135-926f2823-3683-4cd5-be00-c04c312ed42d.png">

### Rejoining of Upstream Concepts
###### Model

`fct_rejoining_of_upstream_concepts` contains all cases where one of the parent's direct children 
is ALSO the direct child of ANOTHER one of the parent's direct children. Only includes cases 
where the model "in between" the parent and child has NO other downstream dependencies.

###### Graph Example

`stg_model_1`, `int_model_4`, and `int_model_5` create a "loop" in the DAG. `int_model_4` has no other downstream dependencies other than `int_model_5`.
<p align = "center">
<img width="800" alt="A DAG showing three resources. A staging model is referenced by both an int model (`int_model_4`) and a second int model (`int_model_5`). `int_model_4` is also being referenced by `int_model_5`. This creates a 'loop' between the staging model, the int model, and the second int model." src="https://user-images.githubusercontent.com/30663534/159788799-6bfb745b-7316-485e-9665-f7e7f825742c.png">

###### Reason to Flag

This could happen for a variety of reasons: Accidentally duplicating some business concepts in multiple 
data flows, hesitance to touch (and break) someone else’s model, or perhaps trying to snowflake out 
or modularize everything without awareness of what will help build time. 

As a general rule, snowflaking out models in a thoughtful manner allows for concurrency, but in this 
example nothing downstream can run until `int_model_4` finishes, so it is not saving any time in 
parallel processing by being its own model. Since both `int_model_4` and `int_model_5` depend solely 
on `stg_model_1`, there is likely a better way to write the SQL within one model (`int_model_5`) and 
simplify the DAG, potentially at the expense of more rows of SQL within the model.

###### Exceptions
  
The one major exception to this would be when using a function from 
[dbt_utils](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/) package, such as `star` or `get_column_values`, 
(or similar functions / packages) that require a [relation](https://docs.getdbt.com/reference/dbt-classes#relation) 
as an argument input. If the shape of the data in the output of `stg_model_1` is not the same as what you 
need for the input to the function within `int_model_5`, then you will indeed need `int_model_4` to create 
that relation, in which case, leave it.
  
###### How to Remediate

Barring jinja/macro/relation exceptions we mention directly above, to resolve this, simply bring the SQL contents from `int_model_4` into a CTE within `int_model_5`, and swap all `{{ ref('int_model_4') }}` references to the new CTE(s).
  
Post-refactor, your DAG should look like this:
  <p align = "center">
<img width="800" alt="A refactored DAG removing the 'loop', by folding `int_model_4` into `int_model_5`." src="https://user-images.githubusercontent.com/30663534/159789475-c5e1a087-1dc9-4d1c-bf13-fba52945ba6c.png">

### Root Models
###### Model

`fct_root_models` shows each model with 0 direct parents, meaning that the model cannot be traced back to a declared source or model in the dbt project. 

###### Graph Example

`model_4` has no direct parents
<p align = "center">
<img width="800" alt="A DAG showing three source tables, each being referenced by a staging model. Each staging model is being referenced by another accompanying model. model_4 is an independent resource not being referenced by any models " src="https://user-images.githubusercontent.com/91074396/156644411-83e269e7-f1f9-4f46-9cfd-bdee1c8e6b22.png">
  
###### Reason to Flag

This likely means that the model (`model_4`  below) contains raw table references, either to a raw data source, or another model in the project without using the `{{ source() }}` or `{{ ref() }}` functions, respectively. This means that dbt is unable to interpret the correct lineage of this model, and could result in mis-timed execution and/or circular references depending on the model’s upstream dependencies. 

###### How to Remediate

Start by mapping any table references in the `FROM` clause of the model definition to the models or raw tables that they draw from, and replace those references with the `{{ ref() }}` if the dependency is another dbt model, or the `{{ source() }}` function if the table is a raw data source (this may require the declaration of a new source table). Then, visualize this model in the DAG, and refactor as appropriate according to best practices. 

###### Exceptions

This behavior may be observed in the case of a manually defined reference table that does not have any dependencies. A good example of this is a `dim_calendar` table that is generated by the `{{ dbt_utils.date_spine() }}` macro — this SQL logic is completely self contained, and does not require any external data sources to execute. 

### Source Fanout
###### Model

`fct_source_fanout` shows each parent/child relationship where a source is the direct parent of multiple resources in the DAG.

###### Graph Example

`source.table_1` has more than one direct child model.
<p align = "center">
<img width="800" alt="" src="https://user-images.githubusercontent.com/91074396/156636403-3bcfdbc3-cf48-4c8f-98dc-addc274ad321.png">
 
###### Reason to Flag

###### How to Remediate

### Unused Sources
###### Model

`fct_unused_sources` shows each source with 0 children.
  
###### Graph Example

`source.table_4` isn't being referenced.
<p align = "center">
<img width="800" alt="A DAG showing three sources which are each being referenced by an accompanying staging model, and one source that isn't being referenced at all" src="https://user-images.githubusercontent.com/91074396/156637881-f67c1a28-93c7-4a91-9337-465aad94b73a.png">

###### Reason to Flag

This represents either a source that you have defined in YML but never brought into a model or a 
model that was deprecated and the corresponding rows in the source block of the YML file were 
not deleted at the same time. This simply represents the buildup of cruft in the project that 
doesn’t need to be there.
  
###### How to Remediate

Navigate to the `sources.yml` file (or whatever your company has called the file) that corresponds 
to the unused source. Within the YML file, remove the unused table name, along with descriptions 
or any other nested information.
  
  ```yaml
  version: 2

  sources:
    - name: some_source
      database: raw
      tables:
        - name: table_1
        - name: table_2
        - name: table_3
        - name: table_4  # <-- remove this line
  ```

Post-refactor, your DAG should look like this:
  <p align = "center">
  <img width="800" alt="A refactored DAG showing three sources which are each being referenced by an accompanying staging model" src="https://user-images.githubusercontent.com/30663534/159603703-6e94b00b-07d1-4f47-89df-8e5685d9fcf0.png"> 

-----

# Limitations

## BigQuery

BigQuery current support for recursive CTEs is limited.

For BigQuery, the model `int_all_dag_relationships` needs to be created by looping CTEs instead. The number of loops is defaulted to 9, which means that dependencies between models of more than 9 levels of separation won't show in the model `int_all_dag_relationships` but tests on the DAG will still be correct. With a number of loops higher than 9 BigQuery sometimes raises an error saying the query is too complex.
