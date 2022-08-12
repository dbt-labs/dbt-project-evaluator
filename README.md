# dbt_project_evaluator

This package highlights areas of a dbt project that are misaligned with dbt Labs' best practices.
Specifically, this package tests for:
  1. __[DAG Issues](#dag-issues)__ - your dbt DAG for modeling best practices
  2. __[Testing](#testing)__ - your models for testing best practices
  3. __[Documentation](#documentation)__ - your models for documentation best practices
  4. __[Structure](#structure)__ - your dbt project for file structure and naming best practices
  5. __[Performance](#performance)__ - your model materializations for performance best practices

In addition to tests, this package creates the model `int_all_dag_relationships` which holds information about your DAG in a tabular format and can be queried using SQL in your Warehouse.

Currently, the following adapters are supported:
- BigQuery
- Databricks/Spark
- PostgreSQL
- Redshift
- Snowflake

## Using This Package

### Cloning via dbt Package Hub
  
Check [dbt Hub](https://hub.getdbt.com/dbt-labs/dbt_project_evaluator/latest/) for the latest installation instructions, or [read the docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
### Additional setup for Databricks/Spark

In your `dbt_project.yml`, add the following config:
```yaml
dispatch:
  - macro_namespace: dbt_utils
    search_order: ['dbt_project_evaluator', 'spark_utils', 'dbt_utils']
```

This is required because the project currently provides limited support for arrays macros for Databricks/Spark which is not part of `spark_utils` yet.
  
### How It Works

This package will:
1. Parse your [graph](https://docs.getdbt.com/reference/dbt-jinja-functions/graph) object and write it into your warehouse as a series of models (see [models/marts/core](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/core))
2. Create another series of models that each represent one type of misalignment in your project (below you can find a full list of each misalignment and its accompanying model)
3. Test those models to alert you to the presence of the misalignment 

Once you've installed the package, all you have to do is run a `dbt build --select package:dbt_project_evaluator`!

----
## Package Documentation

### Rules
- __[DAG Issues](#dag-issues)__
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
- __[Testing](#testing)__
  - [Models without Primary Key Tests](#models-without-primary-key-tests)
  - [Test Coverage](#test-coverage)
- __[Documentation](#documentation)__
  - [Documentation Coverage](#documentation-coverage)
  - [Undocumented Models](#undocumented-models)
- __[Structure](#structure)__
  - [Model Naming Conventions](#model-naming-conventions)
  - [Model Directories](#model-directories)
  - [Source Directories](#model-directories)
  - [Test Directories](#test-directories)
- __[Performance](#performance)__
  - [Chained View Dependencies](#chained-view-dependencies)
  - [Exposure Parents Materializations](#exposure-parents-materializations)

### [Customization](#customization)
- [Disabling Models](#disabling-models)
- [Overriding Variables](#overriding-variables)
- [Configuring exceptions to the rules](#configuring-exceptions-to-the-rules)

### [Querying the DAG with SQL](#querying-the-dag-with-sql)

### [Limitations](#limitations)
- [BigQuery and Databricks](#bigquery-and-databricks)

### [Contributing](#contributing)

----

## DAG Issues

### Direct Join to Source
#### Model

`fct_direct_join_to_source` ([source](models/marts/dag/fct_direct_join_to_source.sql)) shows each parent/child relationship where a model has a reference to
both a model and a source.

#### Example

`int_model_4` is pulling in both a model and a source.

<img width="500" alt="DAG showing a model and a source joining into a new model" src="https://user-images.githubusercontent.com/8754100/167100127-29cdff47-0ef8-41e0-96a2-587021e39769.png">

#### Reason to Flag

We highly recommend having a one-to-one relationship between sources and their corresponding `staging` model, and not having any other model reading from the source. Those `staging` models are then the ones read from by the other downstream models.

This allows renaming your columns and doing minor transformation on your source data only once and being consistent
across all the models that will consume the source data.

#### How to Remediate

In our example, we would want to:
1. create a `staging` model for our source data if it doesn't exist already 
2. and join this `staging` model to other ones to create our downstream transformation instead of using the source

After refactoring your downstream model to select from the staging layer, your DAG should look like this: 

<img width="500" alt="DAG showing two staging models joining into a new model" src="https://user-images.githubusercontent.com/8754100/167100383-ca975328-c1af-4fe9-8729-7d0c81fd36a6.png">

### Downstream Models Dependent on Source
#### Model

`fct_marts_or_intermediate_dependent_on_source` ([source](models/marts/dag/fct_marts_or_intermediate_dependent_on_source.sql)) shows each downstream model (`marts` or `intermediate`)
that depends directly on a source node.

#### Example

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

`fct_model_fanout` ([source](models/marts/dag/fct_model_fanout.sql)) shows all parents with more than 3 direct leaf children.
You can set your own threshold for model fanout by overriding the `models_fanout_threshold` variable. [See overriding variables section.](#overriding-variables)

#### Example

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

`fct_multiple_sources_joined` ([source](models/marts/dag/fct_multiple_sources_joined.sql)) shows each instance where a model references more than one source.

#### Example

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

`fct_rejoining_of_upstream_concepts` ([source](models/marts/dag/fct_rejoining_of_upstream_concepts.sql)) contains all cases where one of the parent's direct children
is ALSO the direct child of ANOTHER one of the parent's direct children. Only includes cases
where the model "in between" the parent and child has NO other downstream dependencies.

#### Example

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

`fct_root_models` ([source](models/marts/dag/fct_root_models.sql)) shows each model with 0 direct parents, meaning that the model cannot be traced back to a declared source or model in the dbt project.

#### Example

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

`fct_source_fanout` ([source](models/marts/dag/fct_source_fanout.sql)) shows each instance where a source is the direct parent of multiple resources in the DAG.

#### Example

`source.table_1` has more than one direct child model.

<img width="500" alt="" src="https://user-images.githubusercontent.com/91074396/167182220-00620844-72c4-45ab-bfe1-48959b0cdf08.png">

#### Reason to Flag

Each source node should be referenced by a single model that performs basic operations, such as renaming, recasting, and other light transformations to maintain consistency through out the project. The role of this staging model is to mirror the raw data but align it with project conventions. The staging model should act as a source of truth and a buffer- any model which depends on the data from a given source should reference the cleaned data in the staging model as opposed to referencing the source directly. This approach keeps the code DRY (any light transformations that need to be done on the raw data are performed only once). Minimizing references to the raw data will also make it easier to update the project should the format of the raw data change.

#### How to Remediate

Create a staging model which references the source and cleans the raw data (e.g. renaming, recasting). Any models referencing the source directly should be refactored to point towards the staging model instead.

After refactoring the above example, the DAG would look something like this:
<img width="500" alt="" src="https://user-images.githubusercontent.com/91074396/167182379-3f74081e-2be9-4db5-a0e9-03d9185efbcc.png">

### Staging Models Dependent on Downstream Models
#### Model

`fct_staging_dependent_on_marts_or_intermediate` ([source](models/marts/dag/fct_staging_dependent_on_marts_or_intermediate.sql)) shows each staging model that depends on an intermediate or marts model, as defined by the naming conventions and folder paths specified in your project variables.

#### Example

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

`fct_staging_dependent_on_staging` ([source](models/marts/dag/fct_staging_dependent_on_staging.sql)) shows each parent/child relationship where models in the staging layer are
dependent on each other.

#### Example

`stg_model_2` is a parent of `stg_model_4`.

<img width="500" alt="A DAG showing stg_model_2 as a parent of stg_model_4." src="https://user-images.githubusercontent.com/53586774/164788355-4c6e58b5-21e0-45c6-bfde-af82952bb495.png">

#### Reason to Flag

This may indicate a change in naming is necessary, or that the child model should instead reference a source.

#### How to Remediate

You should either change the model type of the `child` (maybe to an intermediate or marts model) or change the child's lineage instead reference the appropriate `{{ source() }}`.

In our example, we might realize that `stg_model_4` is _actually_ an intermediate model. We should move this file to the appropriate intermediate directory and update the file name to `int_model_4`.

### Unused Sources
#### Model

`fct_unused_sources` ([source](models/marts/dag/fct_unused_sources.sql)) shows each source with 0 children.

#### Example

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

<img width="500" alt="A refactored DAG showing three sources which are each being referenced by an accompanying staging model" src="https://user-images.githubusercontent.com/30663534/159603703-6e94b00b-07d1-4f47-89df-8e5685d9fcf0.png"> 


## Testing
### Models without Primary Key Tests

#### Model
`fct_missing_primary_key_tests` ([source](models/marts/tests/fct_missing_primary_key_tests.sql)) lists every model that does not meet the minimum testing requirement of testing primary keys. Any models that does not have both a `not_null` and `unique` test configured will be highlighted in this model. 
#### Reason to Flag
Tests are assertions you make about your models and other resources in your dbt project (e.g. sources, seeds and snapshots). Defining tests is a great way to confirm that your code is working correctly, and helps prevent regressions when your code changes. Models without proper tests on their grain are a risk to the reliability and scalability of your project. 
#### How to Remediate
Apply a [uniqueness test](https://docs.getdbt.com/reference/resource-properties/tests#unique) and a [not null test](https://docs.getdbt.com/reference/resource-properties/tests#not_null) to the column that represents the grain of your model in its schema entry. For models that are unique across a combination of columns, we recommend adding a surrogate key column to your model, then applying these tests to that new model. See the [`surrogate_key`](https://github.com/dbt-labs/dbt-utils#surrogate_key-source) macro from dbt_utils for more info!

Additional tests can be configured by applying a [generic test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#generic-tests) in the model's `.yml` entry or by creating a [singular test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#singular-tests) 
in the `tests` directory of you project. 

### Test Coverage
#### Model
`fct_test_coverage` ([source](models/marts/tests/fct_test_coverage.sql)) contains metrics pertaining to project-wide test coverage.
Specifically, this models measures:
1. `test_coverage_pct`: the percentage of your models that have minimum 1 test applied.
2. `test_to_model_ratio`: the ratio of the number of tests in your dbt project to the number of models in your dbt project
3. `< model_type >_test_coverage_pct`: the percentage of each of your model types that have minimum 1 test applied.

This model will raise a `warn` error on a `dbt build` or `dbt test` if the `test_coverage_pct` is less than 100%.
You can set your own threshold by overriding the `test_coverage_target` variable. 
You can adjust your own model types by overriding the `model_types` variable. [See overriding variables section.](#overriding-variables)

#### Reason to Flag
We recommend that every model in your dbt project has tests applied to ensure the accuracy of your data transformations.

#### How to Remediate
Apply a [generic test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#generic-tests) in the model's `.yml` entry, or create a [singular test](https://docs.getdbt.com/docs/building-a-dbt-project/tests#singular-tests)
in the `tests` directory of you project.

As explained above, we recommend [at a minimum](https://www.getdbt.com/analytics-engineering/transformation/data-testing/#what-should-you-test), every model should have `not_null` and `unique` tests set up on a primary key.

## Documentation
### Documentation Coverage
#### Model

`fct_documentation_coverage` ([source](models/marts/documentation/fct_documentation_coverage.sql)) calculates the percent of enabled models in the project that have
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
`fct_undocumented_models` ([source](models/marts/documentation/fct_undocumented_models.sql)) lists every model with no description configured.

#### Reason to Flag
Good documentation for your dbt models will help downstream consumers discover and understand the datasets which you curate for them.
The documentation for your project includes model code, a DAG of your project, any tests you've added to a column, and more.

#### How to Remediate
Apply a text [description](https://docs.getdbt.com/docs/building-a-dbt-project/documentation) in the model's `.yml` entry, or create a [docs block](https://docs.getdbt.com/docs/building-a-dbt-project/documentation#using-docs-blocks) in a markdown file, and use the `{{ doc() }}`
function in the model's `.yml` entry.

Tip: We recommend that every model in your dbt project has at minimum a model-level description. This ensures that each model's purpose is clear to other developers and stakeholders when viewing the dbt docs site. Missing documentation should be addressed first for marts models, then for the rest of your project, to ensure that stakeholders in the organization can understand the data which is surfaced to them.


## Structure
### Model Naming Conventions
#### Model

`fct_model_naming_conventions` ([source](models/marts/structure/fct_model_naming_conventions.sql)) shows all cases where a model does NOT have the appropriate prefix.

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

### Model Directories
#### Model

`fct_model_directories` ([source](models/marts/structure/fct_model_directories.sql)) shows all cases where a model is NOT in the appropriate subdirectory:
- For staging models: The files should be nested in the staging folder of a subfolder that matches their source parent's name.
- For non-staging models: The files should be nested closest to the folder name that matches their model type.  

#### Reason to Flag

Because we often work with multiple data sources, in our staging directory, we create one subdirectory per source.
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
- One .yml file which contains source definitions, tests, and documentation (see [Source Directories](#source-directories))
- One .yml file which contains tests & documentation for models in the same directory (see [Test Directories](#test-directories))

This provides for clear repository organization, so that analytics engineers can quickly and easily find the information they need.

We might create additional folders for intermediate models but each file should always be nested closest to the folder name that matches their model type.
```
├── dbt_project.yml
└── models
    └── marts
        └── fct_model_6.sql
        └── intermediate
            └── int_model_5.sql
```

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

Consider `dim_model_7` which is a marts model but is inappropriately nested closest to the subdirectory `intermediate`:
```
├── dbt_project.yml
└── models
    └── marts
        └── intermediate
            ├── dim_model_7.sql
```

This file should be moved closest to the subdirectory `marts`:
```
├── dbt_project.yml
└── models
    └── marts
        ├── dim_model_7.sql
```

Consider `int_model_4` which is an intermediate model but is inappropriately nested closest to the subdirectory `marts`:
```
├── dbt_project.yml
└── models
    └── marts
        ├── int_model_4.sql
```

This file should be moved closest to the subdirectory `intermediate`:
```
├── dbt_project.yml
└── models
    └── marts
        └── intermediate
            ├── int_model_4.sql
```

### Source Directories
#### Model

`fct_source_directories` ([source](models/marts/structure/fct_source_directories.sql)) shows all cases where a source definition is NOT in the appropriate subdirectory:

#### Reason to Flag

Because we often work with multiple data sources, in our staging directory, we create one subdirectory per source.
```
├── dbt_project.yml
└── models
    ├── marts
    └── staging
        ├── braintree
        └── stripe
```

Each staging directory contains:
- One staging model for each raw source table (see [Model Directories](#source-directories))
- One .yml file which contains source definitions, tests, and documentation
- One .yml file which contains tests & documentation for models in the same directory (see [Test Directories](#test-directories))

This provides for clear repository organization, so that analytics engineers can quickly and easily find the information they need.

#### How to Remediate

For each source flagged, move the file from the `current_file_path` to `change_file_path_to`.

#### Example

Consider `source_2.table_3` which is a `source_2` source but it had been defined inappropriately in a `source.yml` file nested in the subdirectory `source_1`:

```
├── dbt_project.yml
└── models
    ├── marts
    └── staging
        └── source_1
            ├── source.yml
```

This definition should be moved into a `source.yml` file nested in the subdirectory `source_2`:
```
├── dbt_project.yml
└── models
    ├── marts
    └── staging
        ├── source_1
        └── source_2
            ├── source.yml
```

### Test Directories
#### Model

`fct_test_directories` ([source](models/marts/structure/fct_test_directories.sql)) shows all cases where model tests are NOT in the same subdirectory as the corresponding model.

#### Reason to Flag

Each subdirectory in `models/` should contain one .yml file that includes the tests and documentation for all models within the given subdirectory. Keeping your repository organized in this way ensures that folks can quickly access the information they need.

#### How to Remediate

Move flagged tests from the yml file under `current_test_directory` to the yml file under `change_test_directory_to` (create a new yml file if one does not exist).

#### Example

`int_model_4` is located within `marts/`. However, tests for `int_model_4` are configured in `staging/staging.yml`:
```
├── dbt_project.yml
└── models
    └── marts
        ├── int_model_4.sql
    └── staging
        ├── staging.yml
```

A new yml file should be created in `marts/` which contains all tests and documentation for `int_model_4`, and for the rest of the models in located in the `marts/` directory:
```
├── dbt_project.yml
└── models
    └── marts
        ├── int_model_4.sql
        ├── marts.yml
    └── staging
        ├── staging.yml
```

## Performance
### Chained View Dependencies
#### Model

`fct_chained_views_dependencies` ([source](models/marts/performance/fct_chained_views_dependencies.sql)) contains models that are dependent on chains of "non-physically-materialized" models (views and ephemerals), highlighting potential cases for improving performance by switching the materialization of model(s) within the chain to table or incremental. 

This model will raise a `warn` error on a `dbt build` or `dbt test` if the `distance` between a given `parent` and `child` is greater than or equal to 4.
You can set your own threshold for chained views by overriding the `chained_views_threshold` variable. [See overriding variables section.](#overriding-variables)

#### Example

`table_1` depends on a chain of 4 views (`view_1`, `view_2`, `view_3`, and `view_4`).

<img width="500" alt="dag of chain of 4 views, then a table" src="https://user-images.githubusercontent.com/53586774/176299679-39028eb1-f9e3-492a-bdb7-b72d9d7958b7.png">

#### Reason to Flag

You may experience a long runtime for a model when it is build on top of a long chain of "non-physically-materialized" models (views and ephemerals). In the example above, nothing is really computed until you get to `table_1`. At which point, it is going to run the query within `view_4`, which will then have to run the query within `view_3`, which will then have the run the query within `view_2`, which will then have to run the query within `view_1`. These will all be running at the same time, which creates a long runtime for `table_1`. 

#### How to Remediate

We can reduce this compilation time by changing the materialization strategy of some key upstream models to table or incremental to keep a minimum amount of compute in memory and preventing nesting of views. If, for example, we change the materialization of `view_4` from a view to a table, `table_1` will have a shorter runtime as it will have less compilation to do. 

The best practice to determine top candidates for changing materialization from `view` to `table`:
- if a view is used downstream my *many* models, change materialization to table
- if a view has more complex calculations (window functions, joins between *many* tables, etc.), change materialization to table

### Exposure Parents Materializations
#### Model

`fct_exposure_parents_materializations` ([source](models/marts/performance/fct_exposure_parents_materializations.sql)) shows each model that is a direct parent of an exposure and is *not* materialized as a table in the warehouse. 

#### Example 
<img width="500" alt="An example exposure with a table parent (fct_model_6) and an ephemeral parent (dim_model_7)" src="https://user-images.githubusercontent.com/73915542/178068955-742e2c87-4385-48f9-b9fb-94a1cbc8079a.png">

In this case, the parents of `exposure_1` are not both materialized as tables -- `dim_model_7` is ephemeral, while `fct_model_6` is a table. This model would return a record for the `dim_model_7 --> exposure_1` relationship. 

#### Reason to Flag

Models that are referenced by an exposure are likely to be used heavily in downstream systems, and therefore need to be performant when queried. This model highlights instances where the models referenced by exposures are not either a `table` or `incremental` materialization.

#### How to Remediate

If necessary, update the `materialized` configuration on the models returned in `fct_exposure_parents_materializations` to either `table` or `incremental`. This can be done in individual model files using a config block, or for groups of models in your `dbt_project.yml` file. See the docs on [model configurations](https://docs.getdbt.com/reference/model-configs) for more info!

-----
## Customization
### Disabling Models

If there is a particular model or set of models that you *do not want this package to execute*, you can
disable these models as you would any other model in your `dbt_project.yml` file

```yml
# dbt_project.yml

models:
  dbt_project_evaluator:
    marts:
      tests:
        # disable entire test coverage suite
        +enabled: false
      dag:
        # disable single DAG model
        fct_model_fanout:
          +enabled: false

```

### Overriding Variables

Currently, this package uses different variables to adapt the models to your objectives and naming conventions. They can all be updated directly in `dbt_project.yml`

#### Coverage Variables:

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `test_coverage_pct` | the minimum acceptable test coverage percentage | 100% |
| `documentation_coverage_pct` | the minimum acceptable documentation coverage percentage | 100% |

```yml
# dbt_project.yml
# set your test and doc coverage to 75% instead

vars:
  dbt_project_evaluator:
    documentation_coverage_target: 75
    test_coverage_target: 75
```

#### DAG Variables:

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `models_fanout_threshold` | threshold for unacceptable model fanout for `fct_model_fanout` | 3 models |

```yml
# dbt_project.yml
# set your model fanout threshold to 10 instead of 3

vars:
  dbt_project_evaluator:
    models_fanout_threshold: 10
```

#### Naming Convention Variables:

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `model_types` | a list of the different types of models that define the layers of your dbt project | staging, intermediate, marts, other |
| `staging_folder_name` | the name of the folder that contains your staging models | staging |
| `intermediate_folder_name` | the name of the folder that contains your intermediate models | intermediate |
| `marts_folder_name` | the name of the folder that contains your marts models | marts |
| `staging_prefixes` | the list of acceptable prefixes for your staging models | stg_ |
| `intermediate_prefixes` | the list of acceptable prefixes for your intermediate models | int_ |
| `marts_prefixes` | the list of acceptable prefixes for your marts models | fct_, dim_ |
| `other_prefixes` | the list of acceptable prefixes for your other models | rpt_ |

The `model_types`, `<model_type>_folder_name`, and `<model_type>_prefixes` variables allow the package to check if models in the different layers are in the correct folders and have a correct prefix in their name. The default model types are the ones we recommend in our [dbt Labs Style Guide](https://github.com/dbt-labs/corp/blob/main/dbt_style_guide.md). If your model types are different, you can update the `model_types` variable and create new variables for `<model_type>_folder_name` and/or `<model_type>_prefixes`.

```yml
# dbt_project.yml
# add an additional model type "util"

vars:
  dbt_project_evaluator:
    model_types: ['staging', 'intermediate', 'marts', 'other', 'util']
    util_folder_name: 'util'
    util_prefixes: ['util_']
```

#### Performance Variables:

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `chained_views_threshold` | threshold for unacceptable length of chain of views for `fct_chained_views_dependencies` | 4 |

```yml
# dbt_project.yml
# set your chained views threshold to 8 instead of 4

vars:
  dbt_project_evaluator:
    chained_views_threshold: 8
```

#### Warehouse Specific Variables:

| variable    | description | default     |
| ----------- | ----------- | ----------- |
| `max_depth_dag` | limits the number of looped CTEs when computing the DAG end-to-end for BigQuery and Databricks/Spark compatibility | 9 |

Changing `max_depth_dag` number to a higher one might prevent the package from running properly on BigQuery and Databricks/Spark.


### Configuring exceptions to the rules

While the rules defined in this package are considered best practices, we realize that there might be exceptions to those rules and people might want to exclude given results to get passing tests despite not following all the recommendations.

An example would be excluding all models with names matching with `stg_..._unioned` from `fct_multiple_sources_joined` as we might want to union 2 different tables representing the same data in some of our staging models and we don't want the test to fail for those models.

The package offers the ability to define a seed called `dbt_project_evaluator_exceptions.csv` to list those exceptions we don't want to be reported. This seed must contain the following columns:
- `fct_name`: the name of the fact table for which we want to define exceptions (Please note that it is not possible to exclude specific models for all the `coverage` tests, but there are variables available to configure those to the particular users' needs)
- `column_name`: the column name from `fct_name` we will be looking at to define exceptions
- `id_to_exclude`: the values (or `like` pattern) we want to exclude for `column_name`
- `comment`: a field where people can document why a given exception is legitimate

The following section describes the steps to follow to configure exceptions.

#### 1. Create a new seed

With our previous example, the seed `dbt_project_evaluator_exceptions.csv` would look like:
```
fct_name,column_name,id_to_exclude,comment
fct_multiple_sources_joined,child,stg_%_unioned,Models called _unioned can union multiple sources
```

which looks like the following when loaded in the warehouse

|fct_name                   |column_name|id_to_exclude   |comment                                           |
|---------------------------|-----------|----------------|--------------------------------------------------|
|fct_multiple_sources_joined|child      |stg\_%\_unioned |Models called \_unioned can union multiple sources|


#### 2. Deactivate the seed from the original package

Only a single seed can exist with a given name. When using a custom one, we need to deactivate the one from the package by adding the following to our `dbt_project.yml`
```
seeds:
  dbt_project_evaluator:
    dbt_project_evaluator_exceptions:
      +enabled: false
```

#### 3. Run the seed and the package

We then run both the seed and the package by executing the following command:
```
dbt build --select package:dbt_project_evaluator dbt_project_evaluator_exceptions
```


----

## Querying the DAG with SQL

The model `int_all_dag_relationships` ([source](models/marts/core/int_all_dag_relationships.sql)), created with the package, lists all the dbt nodes (models, exposures, sources, metrics, seeds, snapshots) along with all their dependencies (including indirect ones) and the path between them.

Building additional models and snapshots on top of this model could allow:
- creating a dashboard that provides 
  - a list of all the sources used by a given exposure
  - a list of all the exposures or metrics using a given source
  - the dependencies between different models
- building metrics/KPIs on top of a dbt project
  - evolution of the number of models over time
  - evolution of the number of metrics and exposures over time 
- getting insights on potential refactoring work
  - looking at the longest "chains" of models in a project
  - reviewing models with many/few direct dependents
  - identifying potential bottlenecks

----
## Limitations

### BigQuery and Databricks

BigQuery current support for recursive CTEs is limited and Databricks SQL doesn't support recursive CTEs.

For those Data Warehouses, the model `int_all_dag_relationships` needs to be created by looping CTEs instead. The number of loops is configured with `max_depth_dag` and defaulted to 9. This means that dependencies between models of more than 9 levels of separation won't show in the model `int_all_dag_relationships` but tests on the DAG will still be correct. With a number of loops higher than 9 BigQuery sometimes raises an error saying the query is too complex.

----
## Contributing
If you'd like to add models to flag new areas, please update this README and add an integration test
([more details here](https://github.com/dbt-labs/pro-serv-dag-auditing/tree/main/integration_tests#adding-an-integration-test)).
