# Disabling checks from the package

!!! note

    This section is describing how to completely deactivate tests from the package.
    If you are looking to deactivate models/sources from being tested, you can look at [excluding packages and paths](excluding-packages-and-paths.md)

All the tests done as part of the package are tied to `fct` models.

If there is a particular test or set of tests that you *do not want this package to execute*, you can
disable the corresponding `fct` models as you would any other model in your `dbt_project.yml` file

``` yaml title="dbt_project.yml"
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

If you use the `fct_rule_findings_summary` model (for example, for the
dashboard in `integrations/dbt_charts`, which is disabled by default and
opted into via `rule_findings_summary_enabled: true`), also add every
disabled rule's model name to the `rule_findings_summary_exclude` var, so
that model doesn't try to reference a disabled model and fail to compile.
Note that disabling a whole folder (as in the `marts.tests` example above)
disables every `fct_` model in it, not just one - list each one:

``` yaml title="dbt_project.yml"
vars:
  rule_findings_summary_enabled: true
  rule_findings_summary_exclude:
    - 'fct_model_fanout'
    - 'fct_missing_primary_key_tests'
    - 'fct_sources_without_freshness'
    - 'fct_test_coverage'
```

`fct_test_coverage` and `fct_documentation_coverage` are a special case:
they're not rules in `fct_rule_findings_summary`, but the dashboard's
coverage KPIs and chart query them directly by name. Disabling either one
breaks those specific charts even after excluding it above - the board
just won't have anything to show there.
