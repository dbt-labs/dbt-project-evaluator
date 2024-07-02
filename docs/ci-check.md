# Running this package as a CI check

Once you have addressed all current misalignments in your project (either by fixing them or configuring exceptions), you can use this package as a CI check to ensure code changes don't introduce new misalignments. The setup will vary based on whether you are using dbt Cloud or dbt Core, but the general steps are as follows:

## 1. Override test severity with an environment variable

By default the tests in this package are configured with "warn" severity, we can override that for our CI jobs with an environment variable:

1. Create an environment variable to define the appropriate severity for each environment. In dbt Cloud, for example, we can easily create an environment variable `DBT_PROJECT_EVALUATOR_SEVERITY` that is set to "error" for the Continuous Integration environment and "warn" for all other environments:
![Creating DBT_PROJECT_EVALUATOR_SEVERITY environment variable in dbt Cloud](https://user-images.githubusercontent.com/53586774/190683057-cf38d8dd-de70-457c-b65b-3532dc8f5ea1.png)

    Note: It is also possible to use an environment variable for dbt Core, but the actual implementation will depend on how dbt is orchestrated.

1. Update you project.yml file to override the default severity for all tests in this package:

    ```yaml title="dbt_project.yml"
    data_tests:
      dbt_project_evaluator:
        +severity: "{{ env_var('DBT_PROJECT_EVALUATOR_SEVERITY', 'warn') }}"
    ```

    !!! note

        You could follow a similar process to disable the models in this package for your production environment

        ```yaml title="dbt_project.yml"
        models:
          dbt_project_evaluator:
            +enabled: "{{ env_var('DBT_PROJECT_EVALUATOR_ENABLED', 'true') | lower == 'true' | as_bool }}"
        ```

## 2. Run this package for each pull request

Now, you can run this package as a step of your CI job/pipeline. In dbt Cloud, for example, you could update the commands of your CI job to:

```bash
dbt build --select state:modified+ --exclude package:dbt_project_evaluator
dbt build --select package:dbt_project_evaluator
```

Or, if you've [configured any exceptions](customization/exceptions.md), to:

```bash
dbt build --select state:modified+ --exclude package:dbt_project_evaluator
dbt build --select package:dbt_project_evaluator dbt_project_evaluator_exceptions
```

![Add commands dbt build --select state:modified+ --exclude package:dbt_project_evaluator && dbt build --select package:dbt_project_evaluator dbt_project_evaluator_exceptions to CI job in dbt Cloud](https://user-images.githubusercontent.com/53586774/194086949-281cec1b-e6bf-4df2-a63f-302dc3bc4ba6.png){ width=700 }

!!! note

    Ensure you have properly set up your dbt Cloud CI job using deferral and a webhook trigger by following [this documentation](https://docs.getdbt.com/docs/dbt-cloud/using-dbt-cloud/cloud-enabling-continuous-integration).
