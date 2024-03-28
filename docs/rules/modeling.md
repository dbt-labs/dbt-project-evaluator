# Modeling

## Direct Join to Source

`fct_direct_join_to_source` ([source](https://github.com/dbt-labs/dbt-project-evaluator/blob/main/models/marts/dag/fct_direct_join_to_source.sql){:target="_blank"}) shows each parent/child relationship where a model has a reference to
both a model and a source.

**Example**

`int_model_4` is pulling in both a model and a source.

![DAG showing a model and a source joining into a new model](https://user-images.githubusercontent.com/8754100/167100127-29cdff47-0ef8-41e0-96a2-587021e39769.png){ width=500 }

**Reason to Flag**

We highly recommend having a one-to-one relationship between sources and their corresponding `staging` model, and not having any other model reading from the source. Those `staging` models are then the ones read from by the other downstream models.

This allows renaming your columns and doing minor transformation on your source data only once and being consistent
across all the models that will consume the source data.

**How to Remediate**

In our example, we would want to:

1. create a `staging` model for our source data if it doesn't exist already
2. and join this `staging` model to other ones to create our downstream transformation instead of using the source

After refactoring your downstream model to select from the staging layer, your DAG should look like this:

![DAG showing two staging models joining into a new model](https://user-images.githubusercontent.com/8754100/167100383-ca975328-c1af-4fe9-8729-7d0c81fd36a6.png){ width=500 }

---

## Downstream Models Dependent on Source

`fct_marts_or_intermediate_dependent_on_source` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_marts_or_intermediate_dependent_on_source.sql)) shows each downstream model (`marts` or `intermediate`)
that depends directly on a source node.

**Example**

`fct_model_9`, a marts model, builds from `source_1.table_5` a source.

![image](https://user-images.githubusercontent.com/73915542/164775613-74cb7407-4bee-436c-94c8-e3c935bcb87f.png){ width=500 }

**Reason to Flag**

We very strongly believe that a staging model is the atomic unit of data modeling. Each staging
model bears a one-to-one relationship with the source data table it represents. It has the same
granularity, but the columns have been renamed, recast, or usefully reconsidered into a consistent
format. With that in mind, if a `marts` or `intermediate` type model joins directly to a `{{ source() }}`
node, there likely is a missing model that needs to be added.

**How to Remediate**

Add the reference to the appropriate `staging` model to maintain an abstraction layer between your raw data
and your downstream data artifacts.

After refactoring your downstream model to select from the staging layer, your DAG should look like this:

![image](https://user-images.githubusercontent.com/73915542/165100261-cfb7197e-0f39-4ed7-9373-ab4b6e1a4963.png){ width=700 }

---

## Duplicate Sources

`fct_duplicate_sources` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_duplicate_sources.sql)) shows each database object that corresponds to more than one source node.

**Example**

Imagine you have two separate source nodes - `source_1.table_5` and `source_1.raw_table_5`.

![two source nodes in DAG](https://user-images.githubusercontent.com/53586774/226765218-2302deab-8c98-49ce-968a-007ee8ba571a.png){ width=400 }

But both source definitions point to the exact same location in your database - `real_database`.`real_schema`.`table_5`.

```yaml
sources:
  - name: source_1
    schema: real_schema
    database: real_database
    tables:
      - name: table_5
      - name: raw_table_5
        identifier: table_5
```

**Reason to Flag**

If you dbt project has multiple source nodes pointing to the exact same location in your data warehouse, you will have an inaccurate view of your lineage.  

**How to Remediate**

Combine the duplicate source nodes so that each source database location only has a single source definition in your dbt project.

---

## Hard Coded References

`fct_hard_coded_references` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_hard_coded_references.sql)) shows each instance where a model contains hard coded reference(s).

**Example**

`fct_orders` uses hard coded direct relation references (`my_db.my_schema.orders` and `my_schema.customers`).

```sql title="fct_orders.sql"
with orders as (
    select * from my_db.my_schema.orders
),
customers as (
    select * from my_schema.customers
)
select
    orders.order_id,
    customers.name
from orders
left join customers on
  orders.customer_id = customers.id
```

**Reason to Flag**

Always use the `ref` function when selecting from another model and the `source` function when selecting from raw data, rather than using the direct relation reference (e.g. `my_schema.my_table`). Direct relation references are determined via regex mapping [here](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/macros/find_all_hard_coded_references.sql).

The `ref` and `source` functions are part of what makes dbt so powerful! Using these functions allows dbt to infer dependencies (and check that you haven't created any circular dependencies), properly generate your DAG, and ensure that models are built in the correct order. This also ensures that your current model selects from upstream tables and views in the same environment that you're working in.

**How to Remediate**

For each hard coded reference:

- if the hard coded reference is to a model, update the sql to instead use the [ref](https://docs.getdbt.com/reference/dbt-jinja-functions/ref) function
- if the hard coded reference is to raw data, create any needed [sources](https://docs.getdbt.com/docs/build/sources#declaring-a-source) and update the sql to instead use the [source](https://docs.getdbt.com/reference/dbt-jinja-functions/source) function

For the above example, our updated `fct_orders.sql` file would look like:

``` sql title="fct_orders.sql"
with orders as (
    select * from {{ ref('orders') }}
),
customers as (
    select * from {{ ref('customers') }}
)
select
    orders.order_id,
    customers.name
from orders
left join customers on
  orders.customer_id = customers.id
```

---

## Model Fanout

`fct_model_fanout` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_model_fanout.sql)) shows all parents with more than 3 direct leaf children.
You can set your own threshold for model fanout by overriding the `models_fanout_threshold` variable. [See overriding variables section.](../customization/overriding-variables.md)

**Example**

`fct_model` has three direct leaf children.

![A DAG showing three models branching out of a fct model](https://user-images.githubusercontent.com/30663534/159601497-c141c5ba-d3a6-465a-ab8f-12056d28c5ee.png){ width=500 }

**Reason to Flag**

This might indicate some transformations should move to the BI layer, or a common business transformations
should be moved upstream.

**Exceptions**

Some BI tools are better than others at joining and data exploration. For example, with Looker you could
end your DAG after marts (i.e. fcts & dims) and join those artifacts together (with a little know how
and setup time) to make your reports. For others, like Tableau, model fanouts might be more
beneficial, as this tool prefers big tables over joins, so predefining some reports is usually more performant.

To exclude specific cases, check out the instructions in [Configuring exceptions to the rules](../customization/exceptions.md).

**How to Remediate**

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

---

## Multiple Sources Joined

`fct_multiple_sources_joined` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_multiple_sources_joined.sql)) shows each instance where a model references more than one source.

**Example**

`model_1` references two source tables.

![A DAG showing two sources feeding into a staging model](https://user-images.githubusercontent.com/30663534/159605226-14b23d28-1b30-42c9-85a9-3fbe5a41c025.png){ width=500 }

**Reason to Flag**

We very strongly believe that a staging model is the atomic unit of data modeling. Each staging
model bears a one-to-one relationship with the source data table it represents. It has the same
granularity, but the columns have been renamed, recast, or usefully reconsidered into a consistent
format. With that in mind, two `{{ source() }}` declarations in one staging model likely means we are
not being composable enough and there are individual building blocks which could be broken out into
their respective models.

**Exceptions**

Sometimes companies have a bunch of [identical sources across systems](https://discourse.getdbt.com/t/unioning-identically-structured-data-sources/921). When these identical sources will only ever be used collectively, you should union them once and create a staging layer on the combined result.

To exclude specific cases, check out the instructions in [Configuring exceptions to the rules](../customization/exceptions.md).

**How to Remediate**

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

![A refactored DAG showing two staging models feeding into an intermediate model](https://user-images.githubusercontent.com/30663534/159601894-3997eb34-32c2-4a80-a617-537ee96a8cf3.png){ width=500 }

or if you want to use base_ models and keep stg_model_2 as is:

![A refactored DAG showing two base models feeding into a staging model](https://user-images.githubusercontent.com/30663534/159602135-926f2823-3683-4cd5-be00-c04c312ed42d.png){ width=500 }

---

## Rejoining of Upstream Concepts

`fct_rejoining_of_upstream_concepts` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_rejoining_of_upstream_concepts.sql)) contains all cases where one of the parent's direct children
is ALSO the direct child of ANOTHER one of the parent's direct children. Only includes cases
where the model "in between" the parent and child has NO other downstream dependencies.

**Example**

`stg_model_1`, `int_model_4`, and `int_model_5` create a "loop" in the DAG. `int_model_4` has no other downstream dependencies other than `int_model_5`.

<img width="500" alt="A DAG showing three resources. A staging model is referenced by both an int model (`int_model_4`) and a second int model (`int_model_5`). `int_model_4` is also being referenced by `int_model_5`. This creates a 'loop' between the staging model, the int model, and the second int model." src="https://user-images.githubusercontent.com/30663534/159788799-6bfb745b-7316-485e-9665-f7e7f825742c.png">

**Reason to Flag**

This could happen for a variety of reasons: Accidentally duplicating some business concepts in multiple
data flows, hesitance to touch (and break) someone else’s model, or perhaps trying to snowflake out
or modularize everything without awareness of what will help build time.

As a general rule, snowflaking out models in a thoughtful manner allows for concurrency, but in this
example nothing downstream can run until `int_model_4` finishes, so it is not saving any time in
parallel processing by being its own model. Since both `int_model_4` and `int_model_5` depend solely
on `stg_model_1`, there is likely a better way to write the SQL within one model (`int_model_5`) and
simplify the DAG, potentially at the expense of more rows of SQL within the model.

**Exceptions**

The one major exception to this would be when using a function from
[dbt_utils](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/) package, such as `star` or `get_column_values`,
(or similar functions / packages) that require a [relation](https://docs.getdbt.com/reference/dbt-classes#relation)
as an argument input. If the shape of the data in the output of `stg_model_1` is not the same as what you
need for the input to the function within `int_model_5`, then you will indeed need `int_model_4` to create
that relation, in which case, leave it.

To exclude specific cases, check out the instructions in [Configuring exceptions to the rules](../customization/exceptions.md).

**How to Remediate**

Barring jinja/macro/relation exceptions we mention directly above, to resolve this, simply bring the SQL contents from `int_model_4` into a CTE within `int_model_5`, and swap all `{{ ref('int_model_4') }}` references to the new CTE(s).

Post-refactor, your DAG should look like this:

![A refactored DAG removing the 'loop', by folding `int_model_4` into `int_model_5`.](https://user-images.githubusercontent.com/30663534/159789475-c5e1a087-1dc9-4d1c-bf13-fba52945ba6c.png){ width=500 }

---

## Root Models

`fct_root_models` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_root_models.sql)) shows each model with 0 direct parents, meaning that the model cannot be traced back to a declared source or model in the dbt project.

**Example**

`model_4` has no direct parents

![A DAG showing three source tables, each being referenced by a staging model. Each staging model is being referenced by another accompanying model. model_4 is an independent resource not being referenced by any models](https://user-images.githubusercontent.com/91074396/156644411-83e269e7-f1f9-4f46-9cfd-bdee1c8e6b22.png){ width=500 }

**Reason to Flag**</b>

This likely means that the model (`model_4`  below) contains raw table references, either to a raw data source, or another model in the project without using the `{{ source() }}` or `{{ ref() }}` functions, respectively. This means that dbt is unable to interpret the correct lineage of this model, and could result in mis-timed execution and/or circular references depending on the model’s upstream dependencies.

**Exceptions**

This behavior may be observed in the case of a manually defined reference table that does not have any dependencies. A good example of this is a `dim_calendar` table that is generated by the `{{ dbt_utils.date_spine() }}` macro — this SQL logic is completely self contained, and does not require any external data sources to execute.

To exclude specific cases, check out the instructions in [Configuring exceptions to the rules](../customization/exceptions.md).

**How to Remediate**

Start by mapping any table references in the `FROM` clause of the model definition to the models or raw tables that they draw from, and replace those references with the `{{ ref() }}` if the dependency is another dbt model, or the `{{ source() }}` function if the table is a raw data source (this may require the declaration of a new source table). Then, visualize this model in the DAG, and refactor as appropriate according to best practices.

---

## Source Fanout

`fct_source_fanout` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_source_fanout.sql)) shows each instance where a source is the direct parent of multiple resources in the DAG.

**Example**

`source.table_1` has more than one direct child model.

![image](https://user-images.githubusercontent.com/91074396/167182220-00620844-72c4-45ab-bfe1-48959b0cdf08.png){ width=500 }

**Reason to Flag**

Each source node should be referenced by a single model that performs basic operations, such as renaming, recasting, and other light transformations to maintain consistency through out the project. The role of this staging model is to mirror the raw data but align it with project conventions. The staging model should act as a source of truth and a buffer- any model which depends on the data from a given source should reference the cleaned data in the staging model as opposed to referencing the source directly. This approach keeps the code DRY (any light transformations that need to be done on the raw data are performed only once). Minimizing references to the raw data will also make it easier to update the project should the format of the raw data change.

**Exceptions**

NoSQL databases or heavily nested data sources often have so much info json packed into a table
that you need to break one raw data source into multiple base models.

To exclude specific cases, check out the instructions in [Configuring exceptions to the rules](../customization/exceptions.md).

**How to Remediate**

Create a staging model which references the source and cleans the raw data (e.g. renaming, recasting). Any models referencing the source directly should be refactored to point towards the staging model instead.

After refactoring the above example, the DAG would look something like this:

![image](https://user-images.githubusercontent.com/91074396/167182379-3f74081e-2be9-4db5-a0e9-03d9185efbcc.png){ width=500 }

---

## Staging Models Dependent on Downstream Models

`fct_staging_dependent_on_marts_or_intermediate` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_staging_dependent_on_marts_or_intermediate.sql)) shows each staging model that depends on an intermediate or marts model, as defined by the naming conventions and folder paths specified in your project variables.

**Example**

`stg_model_5`, a staging model, builds from `fct_model_9` a marts model.

![image](https://user-images.githubusercontent.com/73915542/164775542-235b5ef8-553d-46ee-9e86-3ff27a6028b5.png){ width=500 }

**Reason to Flag**

This likely represents a misnamed file. According to dbt best practices, staging models should only
select from source nodes. Dependence on downstream models indicates that this model may need to be either
renamed, or reconfigured to only select from source nodes.

**How to Remediate**

Rename the file in the `child` column to use to appropriate prefix, or change the models lineage
by pointing the staging model to the appropriate `{{ source() }}`.

After updating the model to use the appropriate `{{ source() }}` function, your graph should look like this:

![image](https://user-images.githubusercontent.com/73915542/165099955-c7f0e663-e9aa-445b-9954-675f70a1ad82.png){ width=500 }

## Staging Models Dependent on Other Staging Models

`fct_staging_dependent_on_staging` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_staging_dependent_on_staging.sql)) shows each parent/child relationship where models in the staging layer are
dependent on each other.

**Example**

`stg_model_2` is a parent of `stg_model_4`.

![A DAG showing stg_model_2 as a parent of stg_model_4.](https://user-images.githubusercontent.com/53586774/164788355-4c6e58b5-21e0-45c6-bfde-af82952bb495.png){ width=500 }

**Reason to Flag**

This may indicate a change in naming is necessary, or that the child model should instead reference a source.

**How to Remediate**

You should either change the model type of the `child` (maybe to an intermediate or marts model) or change the child's lineage instead reference the appropriate `{{ source() }}`.

In our example, we might realize that `stg_model_4` is _actually_ an intermediate model. We should move this file to the appropriate intermediate directory and update the file name to `int_model_4`.

---

## Unused Sources

`fct_unused_sources` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_unused_sources.sql)) shows each source with 0 children.

**Example**

`source.table_4` isn't being referenced.

![A DAG showing three sources which are each being referenced by an accompanying staging model, and one source that isn't being referenced at all](https://user-images.githubusercontent.com/91074396/156637881-f67c1a28-93c7-4a91-9337-465aad94b73a.png){ width=500 }

**Reason to Flag**

This represents either a source that you have defined in YML but never brought into a model or a
model that was deprecated and the corresponding rows in the source block of the YML file were
not deleted at the same time. This simply represents the buildup of cruft in the project that
doesn’t need to be there.

**How to Remediate**

Navigate to the `sources.yml` file (or whatever your company has called the file) that corresponds
to the unused source. Within the YML file, remove the unused table name, along with descriptions
or any other nested information.

  ```yaml title="sources.yml"
  sources:
    - name: some_source
      database: raw
      tables:
        - name: table_1
        - name: table_2
        - name: table_3
        - name: table_4  # <-- remove this line
  ```

![A refactored DAG showing three sources which are each being referenced by an accompanying staging model](https://user-images.githubusercontent.com/30663534/159603703-6e94b00b-07d1-4f47-89df-8e5685d9fcf0.png){ width=500 }

---

## Models with Too Many Joins

`fct_too_many_joins` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/dag/fct_too_many_joins.sql)) shows models with a reference to too many other models or sources.

The number of different references to start raising errors is set to 7 by default, but you can set your own threshold by overriding the `too_many_joins_threshold` variable. [See overriding variables section.](../customization/overriding-variables.md)

**Example**

`fct_model_1` directly references seven (7) staging models upstream.

![A DAG showing a model that directly references seven staging models upstream.](https://github.com/BradCr/dbt-project-evaluator/assets/151274228/46ea1f78-1bd7-436b-b15b-f63c726601a1){ width=600 }

**Reason to Flag**

This likely represents a model in which too much is being done. Having a model that too many upstream models introduces a lot of code complexity, which can be challenging to understand and maintain.

**How to Remediate**

Bringing together a reasonable number (typically 4 to 6) of entities or concepts (staging models, or perhaps other intermediate models) that will be joined with another similarly purposed intermediate model to generate a mart. Rather than having too many joins, we can join two intermediate models that each house a piece of the complexity, giving us increased readability, flexibility, testing surface area, and insight into our components.

![A DAG showing a model that directly references only two intermediate models. The intermediate models reference three and four staging models upstream.](https://github.com/BradCr/dbt-project-evaluator/assets/151274228/4b630e3c-f13a-443c-94e5-2d93c713c8f2){ width=700 }
