# Excluding packages or sources/models based on their path

!!! note

    This section is describing how to entirely exclude models/sources and packages to be evaluated.
    If you want to ignore results for a specific run, select the resources to check with `--select` and `--exclude` (see [ignoring resources in a given run](exceptions.md#ignoring-resources-in-a-given-run)). To accept violations for good, see the section [on exceptions](exceptions.md)
    and if you want to deactivate entire checks you can follow instructions from [this page](customization.md)

There might be cases where you want to exclude models/sources from being checked:

- they could come from a package for which you have no control over
- you might be refactoring your project and wanting to exclude entire folders to follow best-practices in the new models

In that case, this package provides the ability to exclude whole packages and/or models and sources based on their path

## Configuration

The variables `exclude_packages` and `exclude_paths_from_project` allow you to define a list of packages and paths to exclude from being reported as errors. Excluded resources are ignored by all the checks.

- `exclude_packages` accepts a list of package names to exclude from the tool, or `["all"]` to exclude every package but your own project. Your own project is never excluded, even if you list its name, and the package `dbt_project_evaluator` itself is always excluded
- `exclude_paths_from_project` accepts a list of strings. A resource is excluded when one of those strings appears in
    - its file path (`original_file_path`), for example `models/legacy/` or `/my_date_spine.sql`, allowing to exclude whole folders or individual models
    - or its `unique_id`, for example `raw_crm.contacts` to exclude the source table `contacts` from the source `raw_crm`, as the path of a source is the YAML file that lists all its tables. In the `unique_id`, the `/` characters in the string are removed before looking for a match

!!! warning "Differences with version 1"

    In version 1, `exclude_paths_from_project` accepted regular expressions, case-insensitive, and only applied to the resources of the current project. In version 2:

    - the values are **not** regular expressions. They are matched literally, as a substring, with the SQL operator `LIKE '%<value>%'`: matching is **case-sensitive**, and the characters `%` and `_` are wildcards (`%` for any sequence of characters and `_` for exactly one character). In particular, `.` doesn't mean "any character" anymore
    - they apply to the resources of all the packages, not only the ones of the current project

    `exclude_packages` works as in version 1, including `["all"]`.

The same rules apply to exposures, metrics and saved queries: they are excluded when their package, file path or `unique_id` matches.

### Example to exclude a whole package

```yaml title="dbt_project.yml"
vars:
  exclude_packages: ["upstream_package"]
```

### Example to exclude models/sources in a given path

```yaml title="dbt_project.yml"
vars:
  exclude_paths_from_project: ["models/legacy/"]
```

### Example to exclude all the packages

```yaml title="dbt_project.yml"
vars:
  exclude_packages: ["all"]
```

### Example to exclude both a package and models/sources in 2 different paths

```yaml title="dbt_project.yml"
vars:
  exclude_packages: ["upstream_package"]
  exclude_paths_from_project: ["models/legacy/", "/my_date_spine.sql"]
```

## Tips and tricks

Because the match is a plain substring match, the more specific the value, the better: a short value like `legacy` also excludes the resources whose `unique_id` contains `legacy`. After defining your value for `exclude_paths_from_project`, we recommend running `dbt check` and comparing the number of violations reported with the previous run, or checking the resources that are still evaluated with the information schema (see [querying the DAG](../querying-the-dag.md)).
