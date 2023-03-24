
# Structure

## Model Naming Conventions

`fct_model_naming_conventions` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/structure/fct_model_naming_conventions.sql)) shows all cases where a model does NOT have the appropriate prefix.

**Example**

Consider `model_8` which is nested in the `marts` subdirectory:

```bash
├── dbt_project.yml
└── models
    ├── marts
        └── model_8.sql
```

This model should be renamed to either `fct_model_8` or `dim_model_8`.

**Reason to Flag**

Without appropriate naming conventions, a user querying the data warehouse might incorrectly assume the model type of a given relation. In order to explicitly name
the model type in the data warehouse, we recommend appropriately prefixing your models in dbt.

| Model Type   | Appropriate Prefixes |
| ------------ | -------------------- |
| Staging      | `stg_`               |
| Intermediate | `int_`               |
| Marts        | `fct_` or `dim_`     |
| Other        | `rpt_`               |

**How to Remediate**

For each model flagged, ensure the model type is defined and the model name is prefixed appropriately.

## Model Directories

`fct_model_directories` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/structure/fct_model_directories.sql)) shows all cases where a model is NOT in the appropriate subdirectory:

- For staging models: The files should be nested in the staging folder of a subfolder that matches their source parent's name.
- For non-staging models: The files should be nested closest to the folder name that matches their model type.  

**Example**

Consider `stg_model_3` which is a staging model for `source_2.table_3`:

![A DAG showing source_2.table_3 as a parent of stg_model_3](https://user-images.githubusercontent.com/53586774/161316077-31d6f2a9-2c4a-4dd8-bd18-affe8b3a7367.png){ width=500 }

But, `stg_model_3.sql` is inappropriately nested in the subdirectory `source_1`:

```bash
├── dbt_project.yml
└── models
    ├── marts
    └── staging
        └── source_1
            ├── stg_model_3.sql
```

This file should be moved into the subdirectory `source_2`:

```bash
├── dbt_project.yml
└── models
    ├── marts
    └── staging
        ├── source_1
        └── source_2
            ├── stg_model_3.sql
```

Consider `dim_model_7` which is a marts model but is inappropriately nested closest to the subdirectory `intermediate`:

```bash
├── dbt_project.yml
└── models
    └── marts
        └── intermediate
            ├── dim_model_7.sql
```

This file should be moved closest to the subdirectory `marts`:

```bash
├── dbt_project.yml
└── models
    └── marts
        ├── dim_model_7.sql
```

Consider `int_model_4` which is an intermediate model but is inappropriately nested closest to the subdirectory `marts`:

```bash
├── dbt_project.yml
└── models
    └── marts
        ├── int_model_4.sql
```

This file should be moved closest to the subdirectory `intermediate`:

```bash
├── dbt_project.yml
└── models
    └── marts
        └── intermediate
            ├── int_model_4.sql
```

**Reason to Flag**

Because we often work with multiple data sources, in our staging directory, we create one subdirectory per source.

```bash
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

```bash
├── dbt_project.yml
└── models
    └── marts
        └── fct_model_6.sql
        └── intermediate
            └── int_model_5.sql
```

**How to Remediate**

For each resource flagged, move the file from the `current_file_path` to `change_file_path_to`.

## Source Directories

`fct_source_directories` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/structure/fct_source_directories.sql)) shows all cases where a source definition is NOT in the appropriate subdirectory:

**Example**

Consider `source_2.table_3` which is a `source_2` source but it had been defined inappropriately in a `source.yml` file nested in the subdirectory `source_1`:

```bash
├── dbt_project.yml
└── models
    ├── marts
    └── staging
        └── source_1
            ├── source.yml
```

This definition should be moved into a `source.yml` file nested in the subdirectory `source_2`:

```bash
├── dbt_project.yml
└── models
    ├── marts
    └── staging
        ├── source_1
        └── source_2
            ├── source.yml
```

**Reason to Flag**

Because we often work with multiple data sources, in our staging directory, we create one subdirectory per source.

```bash
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

**How to Remediate**

For each source flagged, move the file from the `current_file_path` to `change_file_path_to`.

## Test Directories

`fct_test_directories` ([source](https://github.com/dbt-labs/dbt-project-evaluator/tree/main/models/marts/structure/fct_test_directories.sql)) shows all cases where model tests are NOT in the same subdirectory as the corresponding model.

**Example**

`int_model_4` is located within `marts/`. However, tests for `int_model_4` are configured in `staging/staging.yml`:

```bash
├── dbt_project.yml
└── models
    └── marts
        ├── int_model_4.sql
    └── staging
        ├── staging.yml
```

A new yml file should be created in `marts/` which contains all tests and documentation for `int_model_4`, and for the rest of the models in located in the `marts/` directory:

```bash
├── dbt_project.yml
└── models
    └── marts
        ├── int_model_4.sql
        ├── marts.yml
    └── staging
        ├── staging.yml
```

**Reason to Flag**

Each subdirectory in `models/` should contain one .yml file that includes the tests and documentation for all models within the given subdirectory. Keeping your repository organized in this way ensures that folks can quickly access the information they need.

**How to Remediate**

Move flagged tests from the yml file under `current_test_directory` to the yml file under `change_test_directory_to` (create a new yml file if one does not exist).
