# Excluding packages or sources/models based on their path

!!! note

    This section is describing how to entirely exclude models/sources and packages to be evaluated.
    If you want to document exceptions to the rules, see the section [on exceptions](exceptions.md)
    and if you want to deactivate entire tests you can follow instructions from [this page](customization.md)

There might be cases where you want to exclude models/sources from being tested:

- they could come from a package for which you have no control over
- you might be refactoring your project and wanting to exclude entire folders to follow best-practices in the new models

In that case, this package provides the ability to exclude whole packages and/or models and sources based on their path

## Configuration

The variables `exclude_packages` and `exclude_paths_from_project` allow you to define a list of regex patterns to exclude from being reported as errors.

- `exclude_packages` accepts a list of package names to exclude from the tool. To exclude all packages except the current project, you can set it to `["all"]`
- `exclude_paths_from_project` accepts a list of regular expressions of paths to exclude for the current project
    - **for models**, the regex provided will try to match the pattern in the string `<path/to/model.sql>`, allowing to exclude packages, but also whole folders or individual models
    - **for sources**, the regex will try to match the pattern in `<path/to/sources.yml>:<source_name>.<source_table_name>` *(the pattern is different than for models because the path itself doesn't let us exclude individual sources)*

!!! note

    We currently don't allow excluding metrics and exposures, as if those need to be entirely excluded they could be deactivated from the project.
    
    If you have a specific use case requiring this ability, please raise a GitHub issue to explain the situation you'd like to solve and we can revisit this decision !

### Example to exclude a whole package

```yaml title="dbt_project.yml"
vars:
  exclude_packages: ["upstream_package"]
```

### Example to exclude models/sources in a given path

```yaml title="dbt_project.yml"
vars:
  exclude_paths_from_project: ["/models/legacy/"]
```

### Example to exclude both a package and models/sources in 2 different paths

```yaml title="dbt_project.yml"
vars:
  exclude_packages: ["upstream_package"]
  exclude_paths_from_project: ["/models/legacy/", "/my_date_spine.sql"]
```

## Tips and tricks

Regular expressions are very powerful but can become complex. After defining your value for `exclude_paths_from_project`, we recommend running the package and inspecting the model `int_all_graph_resources`, checking if the value in the column `is_excluded` matches your expectation.

A useful tool to debug regular expression is [regex101](https://regex101.com/). You can provide a pattern and a list of strings to see which ones actually match the pattern.
