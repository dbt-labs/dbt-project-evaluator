# Excluding packages or sources/models based on their path

!!! note

    This section is describing how to entirely exclude models/sources and packages to be evaluated.
    If you want to document exception to the rules, see the section [on exceptions](exceptions.md)
    and if you want to deactivate entire tests you can follow instructions from [this page](customization.md)

There might be cases where you might want to exclude models/sources from being tested:

- they could come from a package for which you have no control over
- you might be refactoring your project and wanting to exclude entire folders to follow best-practices in the new models

In that case, this package provides the ability to exclude whole packages and/or models and sources based on their path

## Configuration

The variable `exclude_packages_and_paths` allows you to define a list of regex patterns to exclude from being reported as errors.

- **for models**, the regex provided will try to match the pattern in the string `<package>:<path/to/model.sql>`, allowing to exclude packages, but also whole folders or individual models
- **for sources**, the regex will try to match the pattern in `<package>:<path/to/sources.yml>:<source_table_name>` *(the pattern is different than for models because the path doesn't let us exclude individual sources)*

### Example to exclude a whole package

```yaml title="dbt_project.yml"
vars:
  exclude_packages_and_paths: ["<package_name>:.*"]
```

### Example to exclude a given path

```yaml title="dbt_project.yml"
vars:
  exclude_packages_and_paths: [".*/<path_to_exclude>/.*"]
```

### Example to exclude both a package and models in a path

```yaml title="dbt_project.yml"
vars:
  exclude_packages_and_paths: ["<package_name>:.*", ".*/<path_to_exclude>/.*"]
```

## Tips and tricks

Regular expressions are very powerful but can become complex. After defining your value for `exclude_packages_and_paths`, we recommend running the package and inspecting the model `int_all_graph_resources`, checking if the value in the column `is_disabled` matches your expectation.

A useful tool to debug regular expression is [regex101](https://regex101.com/). You can provide a pattern and a list of strings to see which ones actually match the pattern.

### Running the tests only on the current project

Instead of listing all the packages to exclude, we can use a [regex negative look-ahead](https://www.regular-expressions.info/lookaround.html) expression to filter out all the models and sources that come from a package different than the current project.

```yaml title="dbt_project.yml"
vars:
  exclude_packages_and_paths: ["^(?!<your_project_name>:).*"]
```

This expression will exclude all the nodes that don't start with `<your_project_name>:`, e.g. all the nodes coming from imported packages:

- `^` : we search for the beginning of a string
- `(?! ... )` : not immediately followed
- by `<your_project_name>:`
- `.*` : with whatever characters after
