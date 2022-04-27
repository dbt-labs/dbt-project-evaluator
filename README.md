# dbt_project_evaluator

This package highlights areas of a dbt project that are misaligned with dbt Labs' best practices.
Specifically, this package tests for:
  1. __[DAG Issues](#dag-issues)__ - your dbt DAG for modeling best practices
  2. __[Testing](#testing)__ - your models for testing best practices
  3. __[Documentation](#documentation)__ - your models for documentation best practices
  3. __[Structure](#structure)__ - your dbt project for file structure and naming best practices

## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/dbt-labs/dbt_project_evaluator/latest/) for the latest installation instructions, or [read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

----
## Package Documentation

__[DAG Issues](#dag-issues)__
- [Direct Join to Source](#direct-join-to-source)
- [Downstream Models Dependent on Source](#downstream-models-dependent-on-source)
- [Model Fanout](#model-fanout)
- [Multiple Sources Joined](#multiple-sources-joined)
- [Rejoining of Upstream Concepts](#rejoining-of-upstream-concepts)
- [Root Models](#root-models)
- [Source Fanout](#source-fanout)
- [Staging Models Dependent on Downstream Models](#staging-models-dependent-on-downstream-models)
- [Staging Models Dependent on Other Staging Models](#staging-models-dependent-on-other-staging-models)
- [Unused Sources](#unused-sources)

__[Testing](#testing)__
- [Test Coverage](#test-coverage)
- [Untested Models](#untested-models)

__[Documentation](#documentation)__
- [Documentation Coverage](#documentation-coverage)
- [Undocumented Models](#undocumented-models)

__[Structure](#structure)__
- [Model Naming Conventions](#model-naming-conventions)
- [Staging Directories](#staging-directories)

----

## DAG Issues

### Direct Join to Source
#### Model

`fct_direct_join_to_source` ([source](models/dag/fct_direct_join_to_source.sql)) shows each parent/child relationship where a model has a reference to 
both a model and a source.

#### Graph Example

`model_2` is pulling in both a model and a source.

<img width="500" alt="DAG showing a model and a source joining into a new model" src="https://user-images.githubusercontent.com/91074396/156454034-1f516133-ae52-48d6-9204-2358441ebb44.png">
  
#### Reason to Flag

#### How to Remediate


### Downstream Models Dependent on Source
#### Model

`fct_marts_or_intermediate_dependent_on_source` ([source](models/dag/fct_marts_or_intermediate_dependent_on_source.sql)) shows each downstream model (`marts` or `intermediate`) 
that depends directly on a source node.
  
#### Graph Example

`fct_model_9`, a marts model, builds from `source_1.table_5` a source.
<img width="500" alt="image" src="https://user-images.githubusercontent.com/73915542/164775613-74cb7407-4bee-436c-94c8-e3c935bcb87f.png">

#### Reason to Flag

We very strongly believe that a staging model is the atomic unit of data modeling. Each staging 
model bears a one-to-one relationship with the source data table it represents. It has the same 
granularity, but the columns have been renamed, recast, or usefully reconsidered into a consistent 
format. With that in mind, if a `marts` or `intermediate` type model joins directly to a `{{ source() }}` 
node, there likely is a missing model that needs to be added.  
  
#### How to Remediate

Add the reference to the appropriate `staging` model to maintain an abstraction layer between your raw data
and your downstream data artifacts.
  
After refactoring your downstream model to select from the staging layer, your DAG should look like this:
<img width="500" alt="image" src="https://user-images.githubusercontent.com/73915542/165100261-cfb7197e-0f39-4ed7-9373-ab4b6e1a4963.png">
### Model Fanout
#### Model

`fct_model_fanout` ([source](models/dag/fct_model_fanout.sql)) shows all parents with more direct leaf children than the threshold for fanout 
(determined by variable `models_fanout_threshold`, default 3)
  
#### Graph Example

`fct_model` has three direct leaf children.

<img width="500" alt="A DAG showing three models branching out of a fct model" src="https://user-images.githubusercontent.com/30663534/159601497-c141c5ba-d3a6-465a-ab8f-12056d28c5ee.png">

#### Reason to Flag

This might indicate some transformations should move to the BI layer, or a common business transformations
should be moved upstream.

#### Exceptions

Some BI tools are better than others at joining and data exploration. For example, with Looker you could 
end your DAG after marts (i.e. fcts & dims) and join those artifacts together (with a little know how 
and setup time) to make your reports. For others, like Tableau, model fanouts might be more 
beneficial, as this tool prefers big tables over joins, so predefining some reports is usually more performant. 
  
#### How to Remediate

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
#### Model

`fct_multiple_sources_joined` ([source](models/dag/fct_multiple_sources_joined.sql)) shows each instance where a model references more than one source.

#### Graph Example

`model_1` references two source tables.

<img width="500" alt="A DAG showing two sources feeding into a staging model" src="https://user-images.githubusercontent.com/30663534/159605226-14b23d28-1b30-42c9-85a9-3fbe5a41c025.png"> 
  
#### Reason to Flag

We very strongly believe that a staging model is the atomic unit of data modeling. Each staging 
model bears a one-to-one relationship with the source data table it represents. It has the same 
granularity, but the columns have been renamed, recast, or usefully reconsidered into a consistent 
format. With that in mind, two `{{ source() }}` declarations in one staging model likely means we are 
not being composable enough and there are individual building blocks which could be broken out into
their respective models. 

#### Exceptions
  
NoSQL databases or heavily nested data sources often have so much info json packed into a table 
that you need to break one raw data source into multiple base models.

Also, sometimes companies will have a bunch of [identical sources across systems](https://discourse.getdbt.com/t/unioning-identically-structured-data-sources/921) and you union them once before you stage them.

These make total sense, and you should keep them in your project. To continue to test your project, you can 
count those instances, then add a [warn_if](https://docs.getdbt.com/reference/resource-configs/severity) 
threshold to the test to account for the known examples.
  
#### How to Remediate

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

<img width="500" alt="A refactored DAG showing two staging models feeding into an intermediate model" src="https://user-images.githubusercontent.com/30663534/159601894-3997eb34-32c2-4a80-a617-537ee96a8cf3.png">

or if you want to use base_ models and keep stg_model_2 as is:
  
<img width="500" alt="A refactored DAG showing two base models feeding into a staging model" src="https://user-images.githubusercontent.com/30663534/159602135-926f2823-3683-4cd5-be00-c04c312ed42d.png">

### Rejoining of Upstream Concepts
#### Model

`fct_rejoining_of_upstream_concepts` ([source](models/dag/fct_rejoining_of_upstream_concepts.sql)) contains all cases where one of the parent's direct children 
is ALSO the direct child of ANOTHER one of the parent's direct children. Only includes cases 
where the model "in between" the parent and child has NO other downstream dependencies.

#### Graph Example

`stg_model_1`, `int_model_4`, and `int_model_5` create a "loop" in the DAG. `int_model_4` has no other downstream dependencies other than `int_model_5`.

<img width="500" alt="A DAG showing three resources. A staging model is referenced by both an int model (`int_model_4`) and a second int model (`int_model_5`). `int_model_4` is also being referenced by `int_model_5`. This creates a 'loop' between the staging model, the int model, and the second int model." src="https://user-images.githubusercontent.com/30663534/159788799-6bfb745b-7316-485e-9665-f7e7f825742c.png">

#### Reason to Flag

This could happen for a variety of reasons: Accidentally duplicating some business concepts in multiple 
data flows, hesitance to touch (and break) someone else’s model, or perhaps trying to snowflake out 
or modularize everything without awareness of what will help build time. 

As a general rule, snowflaking out models in a thoughtful manner allows for concurrency, but in this 
example nothing downstream can run until `int_model_4` finishes, so it is not saving any time in 
parallel processing by being its own model. Since both `int_model_4` and `int_model_5` depend solely 
on `stg_model_1`, there is likely a better way to write the SQL within one model (`int_model_5`) and 
simplify the DAG, potentially at the expense of more rows of SQL within the model.

#### Exceptions
  
The one major exception to this would be when using a function from 
[dbt_utils](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/) package, such as `star` or `get_column_values`, 
(or similar functions / packages) that require a [relation](https://docs.getdbt.com/reference/dbt-classes#relation) 
as an argument input. If the shape of the data in the output of `stg_model_1` is not the same as what you 
need for the input to the function within `int_model_5`, then you will indeed need `int_model_4` to create 
that relation, in which case, leave it.
  
#### How to Remediate

Barring jinja/macro/relation exceptions we mention directly above, to resolve this, simply bring the SQL contents from `int_model_4` into a CTE within `int_model_5`, and swap all `{{ ref('int_model_4') }}` references to the new CTE(s).
  
Post-refactor, your DAG should look like this:

<img width="500" alt="A refactored DAG removing the 'loop', by folding `int_model_4` into `int_model_5`." src="https://user-images.githubusercontent.com/30663534/159789475-c5e1a087-1dc9-4d1c-bf13-fba52945ba6c.png">

### Root Models
#### Model

`fct_root_models` ([source](models/dag/fct_root_models.sql)) shows each model with 0 direct parents, meaning that the model cannot be traced back to a declared source or model in the dbt project. 

#### Graph Example

`model_4` has no direct parents

<img width="500" alt="A DAG showing three source tables, each being referenced by a staging model. Each staging model is being referenced by another accompanying model. model_4 is an independent resource not being referenced by any models " src="https://user-images.githubusercontent.com/91074396/156644411-83e269e7-f1f9-4f46-9cfd-bdee1c8e6b22.png">
  
#### Reason to Flag

This likely means that the model (`model_4`  below) contains raw table references, either to a raw data source, or another model in the project without using the `{{ source() }}` or `{{ ref() }}` functions, respectively. This means that dbt is unable to interpret the correct lineage of this model, and could result in mis-timed execution and/or circular references depending on the model’s upstream dependencies. 

#### How to Remediate

Start by mapping any table references in the `FROM` clause of the model definition to the models or raw tables that they draw from, and replace those references with the `{{ ref() }}` if the dependency is another dbt model, or the `{{ source() }}` function if the table is a raw data source (this may require the declaration of a new source table). Then, visualize this model in the DAG, and refactor as appropriate according to best practices. 

#### Exceptions

This behavior may be observed in the case of a manually defined reference table that does not have any dependencies. A good example of this is a `dim_calendar` table that is generated by the `{{ dbt_utils.date_spine() }}` macro — this SQL logic is completely self contained, and does not require any external data sources to execute. 

### Source Fanout
#### Model

`fct_source_fanout` ([source](models/dag/fct_source_fanout.sql)) shows each instance where a source is the direct parent of multiple resources in the DAG.

#### Graph Example

`source.table_1` has more than one direct child model.

<img width="500" alt="" src="https://user-images.githubusercontent.com/91074396/156636403-3bcfdbc3-cf48-4c8f-98dc-addc274ad321.png">
 
#### Reason to Flag

#### How to Remediate

### Staging Models Dependent on Downstream Models
#### Model

`fct_staging_dependent_on_marts_or_intermediate` ([source](models/dag/fct_staging_dependent_on_marts_or_intermediate.sql)) shows each staging model that depends on an intermediate or marts model, as defined by the naming conventions and folder paths specified in your project variables. 
  
#### Graph Example

`stg_model_5`, a staging model, builds from `fct_model_9` a marts model.

<img width="500" alt="image" src="https://user-images.githubusercontent.com/73915542/164775542-235b5ef8-553d-46ee-9e86-3ff27a6028b5.png">

#### Reason to Flag

This likely represents a misnamed file. According to dbt best practices, staging models should only 
select from source nodes. Dependence on downstream models indicates that this model may need to be either 
renamed, or reconfigured to only select from source nodes. 
  
#### How to Remediate

Rename the file in the `child` column to use to appropriate prefix, or change the models lineage
by pointing the staging model to the appropriate `{{ source() }}`. 

After updating the model to use the appropriate `{{ source() }}` function, your graph should look like this:

<img width="500" alt="image" src="https://user-images.githubusercontent.com/73915542/165099955-c7f0e663-e9aa-445b-9954-675f70a1ad82.png">

### Staging Models Dependent on Other Staging Models
#### Model

`fct_staging_dependent_on_staging` ([source](models/dag/fct_staging_dependent_on_staging.sql)) shows each parent/child relationship where models in the staging layer are 
dependent on each other.

#### Graph Example

`stg_model_2` is a parent of `stg_model_4`.

<img width="500" alt="A DAG showing stg_model_2 as a parent of stg_model_4." src="https://user-images.githubusercontent.com/53586774/164788355-4c6e58b5-21e0-45c6-bfde-af82952bb495.png">

#### Reason to Flag

This may indicate a change in naming is necessary, or that the child model should instead reference a source. 

#### How to Remediate

You should either change the model type of the `child` (maybe to an intermediate or marts model) or change the child's lineage instead reference the appropriate `{{ source() }}`. 

In our example, we might realize that `stg_model_4` is _actually_ an intermediate model. We should move this file to the appropriate intermediate direcory and update the file name to `int_model_4`.

### Unused Sources
#### Model

`fct_unused_sources` ([source](models/dag/fct_unused_sources.sql)) shows each source with 0 children.
  
#### Graph Example

`source.table_4` isn't being referenced.

<img width="500" alt="A DAG showing three sources which are each being referenced by an accompanying staging model, and one source that isn't being referenced at all" src="https://user-images.githubusercontent.com/91074396/156637881-f67c1a28-93c7-4a91-9337-465aad94b73a.png">

#### Reason to Flag

This represents either a source that you have defined in YML but never brought into a model or a 
model that was deprecated and the corresponding rows in the source block of the YML file were 
not deleted at the same time. This simply represents the buildup of cruft in the project that 
doesn’t need to be there.
  
#### How to Remediate

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

<img width="500" alt="A refactored DAG showing three sources which are each being referenced by an accompanying staging model" src="https://user-images.githubusercontent.com/30663534/159603703-6e94b00b-07d1-4f47-89df-8e5685d9fcf0.png"> 

## Testing
### Test Coverage
#### Model
`fct_test_coverage` ([source](models/tests/fct_test_coverage.sql)) contains metrics pertaining to project-wide test coverage. 
Specifically, this models measures:
1. `test_coverage_pct`: the percentage of your models have minimum 1 test applied. 
2. `test_to_model_ratio`: the ratio of the number of tests in your dbt project to the number of models in your dbt project

This model will raise a `warn` error on a `dbt build` or `dbt test` if the `test_coverage_pct` is less than 100%. 
You can set your own threshold by overriding the `test_coverage_target` variable. [See overriding variables section.](#overriding-variables)

#### Reason to Flag
We recommend that every model in your dbt project has tests applied to ensure the accuracy of your data transformations.

#### How to Remediate
Apply a [generic test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#generic-tests) in the model's `.yml` entry, or create a [singular test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#singular-tests) 
in the `tests` directory of you project. 

Tip: We recommend [at a minimum](https://www.getdbt.com/analytics-engineering/transformation/data-testing/#what-should-you-test), every model should have `not_null` and `unique` tests set up on a primary key.

### Untested Models
#### Model
`fct_untested_models` ([source](models/tests/fct_untested_models.sql)) lists every model that has no tests applied.

#### Reason to Flag
Tests are assertions you make about your models and other resources in your dbt project (e.g. sources, seeds and snapshots). Defining tests is a great way to confirm that your code is working correctly, and helps prevent regressions when your code changes. Models that are missing tests are a risk to the reliability and scalability of your project. 

#### How to Remediate
Apply a [generic test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#generic-tests) in the model's `.yml` entry, or create a [singular test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#singular-tests) 
in the `tests` directory of you project. 

Tip: We recommend [at a minimum](https://www.getdbt.com/analytics-engineering/transformation/data-testing/#what-should-you-test), every model should have `not_null` and `unique` tests set up on a primary key.

## Documentation
### Documentation Coverage
#### Model

`fct_documentation_coverage` ([source](models/documentation/fct_documentation_coverage.sql)) calculates the percent of enabled models in the project that have 
a configured description.

This model will raise a `warn` error on a `dbt build` or `dbt test` if the `documentation_coverage_pct` is less than 100%. 
You can set your own threshold by overriding the `test_coverage_target` variable. [See overriding variables section.](#overriding-variables)

#### Reason to Flag
Good documentation for your dbt models will help downstream consumers discover and understand the datasets which you curate for them.
The documentation for your project includes model code, a DAG of your project, any tests you've added to a column, and more.

#### How to Remediate
Apply a text [description](https://docs.getdbt.com/docs/building-a-dbt-project/documentation#related-documentation) in the model's `.yml` entry, or create a [docs block](https://docs.getdbt.com/docs/building-a-dbt-project/documentation#using-docs-blocks) in a markdown file, and use the `{{ doc() }}`
function in the model's `.yml` entry.

Tip: We recommend that every model in your dbt project has at minimum a model-level description. This ensures that each model's purpose is clear to other developers and stakeholders when viewing the dbt docs site.
### Undocumented Models
#### Model
`fct_undocumented_models` ([source](models/documentation/fct_undocumented_models.sql)) lists every model with no description configured.

#### Reason to Flag
Good documentation for your dbt models will help downstream consumers discover and understand the datasets which you curate for them.
The documentation for your project includes model code, a DAG of your project, any tests you've added to a column, and more.

#### How to Remediate
Apply a text [description](https://docs.getdbt.com/docs/building-a-dbt-project/documentation) in the model's `.yml` entry, or create a [docs block](https://docs.getdbt.com/docs/building-a-dbt-project/documentation#using-docs-blocks) in a markdown file, and use the `{{ doc() }}`
function in the model's `.yml` entry.

Tip: We recommend that every model in your dbt project has at minimum a model-level description. This ensures that each model's purpose is clear to other developers and stakeholders when viewing the dbt docs site.


## Structure 
### Model Naming Conventions
#### Model

`fct_model_naming_conventions` ([source](models/structure/fct_model_naming_conventions.sql)) shows all cases where a model does NOT have the appropriate prefix. 

#### Reason to Flag

Without appropriate naming conventions, a user querying the data warehouse might incorrectly assume the model type of a given relation. In order to explicitly name 
the model type in the data warehouse, we recommend appropriately prefixing your models in dbt. 

| Model Type   | Appropriate Prefixes |
| ------------ | -------------------- |
| Staging      | `stg_`               |
| Intermediate | `int_`               |
| Marts        | `fct_` or `dim_`     |
| Other        | `rpt_`               |

#### How to Remediate

For each model flagged, ensure the model type is defined and the model name is prefixed appropriately. 

#### Example

Consider `model_8` which is nested in the `marts` subdirectory:
```
├── dbt_project.yml
└── models
    ├── marts
        └── model_8.sql
```

This model should be renamed to either `fct_model_8` or `dim_model_8`.

-----
### Staging Directories
#### Model

`fct_staging_directories` ([source](models/structure/fct_staging_directories.sql)) shows all cases where a staging model or source definition is NOT in the appropriate subdirectory.

#### Reason to Flag

Because we often work with multiple data sources, in our staging directory, we create one directory per source. 
```
├── dbt_project.yml
└── models
    ├── marts
    └── staging
        ├── braintree
        └── stripe
```

Each staging directory contains:
- One staging model for each raw source table
- One .yml file which contains source definitions, tests, and documentation
- One .yml file which contains tests & documentation for models in the same directory

This provides for clear repository organization, so that analytics engineers can quickly and easily find the information they need.

#### How to Remediate

For each resource flagged, move the file from the `current_file_path` to `change_file_path_to`. 

#### Example

Consider `stg_model_3` which is a staging model for `source_2.table_3`:

<img width="500" alt="A DAG showing source_2.table_3 as a parent of stg_model_3" src="https://user-images.githubusercontent.com/53586774/161316077-31d6f2a9-2c4a-4dd8-bd18-affe8b3a7367.png">

But, `stg_model_3.sql` is inappropriately nested in the subdirectory `source_1`:
```
├── dbt_project.yml
└── models
    ├── marts
    └── staging
        └── source_1
            ├── stg_model_3.sql
```

This file should be moved into the subdirectory `source_2`:
```
├── dbt_project.yml
└── models
    ├── marts
    └── staging
        ├── source_1
        └── source_2
            ├── stg_model_3.sql
```



## Customization
### Disabling models

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

### Overriding Variables

Currently, this package uses two variables to set the targets for a project's `test_coverage_pct` and `documentation_coverage_pct`, 
each of which are defaulted to 100% coverage. If you would like to override these defaults, you can do so by supplying your own 
values in your dbt_project.yml

```yml
# dbt_project.yml
# set your test and doc coverage to 75% instead

vars:
  dbt_project_evaluator:
    documentation_coverage_target: 75
    test_coverage_target: 75

```

----
## Limitations

### BigQuery

BigQuery current support for recursive CTEs is limited.

For BigQuery, the model `int_all_dag_relationships` needs to be created by looping CTEs instead. The number of loops is defaulted to 9, which means that dependencies between models of more than 9 levels of separation won't show in the model `int_all_dag_relationships` but tests on the DAG will still be correct. With a number of loops higher than 9 BigQuery sometimes raises an error saying the query is too complex.

----
## Contributing
If you'd like to add models to flag new areas, please update this README and add an integration test 
([more details here](https://github.com/dbt-labs/pro-serv-dag-auditing/tree/main/integration_tests#adding-an-integration-test)).
