# Test dbt Project

The models within this folder (barring those in models/audit_schema_tests) represent a dbt project with poor DAG modeling. Error detection tools within this package are tested on this dbt project.

<img width="1377" alt="DAG of the test dbt project" src="https://user-images.githubusercontent.com/73915542/170353654-58ad303c-adaa-49f6-86b8-723543eb2d3d.png">

## Adding an Integration Test
Create a seed which matches the intended output of your model and add equality tests comparing the output to your seed to the output of your model.

## Local tests

### AWS Athena

To run tests locally, please follow instructions:

* Set up environment variables:

```bash
ATHENA_S3_STAGING_DIR=
ATHENA_S3_DATA_DIR=
ATHENA_REGION=
ATHENA_SCHEMA=
ATHENA_WORKGROUP=
```

* Add `profiles.yml` file based on [sample](ci/sample.profiles.yml):

```yaml
    athena: # for local tests only
      type: athena
      s3_staging_dir: {{ env_var('ATHENA_S3_STAGING_DIR') }}
      s3_data_dir: {{ env_var('ATHENA_S3_DATA_DIR') }}
      s3_data_naming: schema_table_unique
      region_name: {{ env_var('ATHENA_REGION') }}
      schema: {{ env_var('ATHENA_SCHEMA') }}
      database: awsdatacatalog
      work_group: {{ env_var('ATHENA_WORKGROUP') }}
      num_retries: 2
      threads: 4
```

* Now you can run integration tests, see details [here](../run_test.sh) with `--target athena` flag for dbt commands.
