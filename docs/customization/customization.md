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

## Dashboard prerequisite

The dashboard in `integrations/dbt_charts` (powered by `fct_rule_findings_summary`,
disabled by default and opted into via `rule_findings_summary_enabled: true`)
assumes **every rule in this package is enabled**. Both `fct_rule_findings_summary`
and the dashboard's own per-rule tabs reference every rule's `fct_` model -
and `fct_test_coverage`/`fct_documentation_coverage` - directly and
unconditionally. If you've disabled any of those via `+enabled: false`
(including a whole folder, like the `marts.tests` example above, which
disables every `fct_` model in it), don't enable the dashboard until you
re-enable that rule - a disabled model's `ref()` fails compilation outright,
rather than just leaving one chart empty. See
`integrations/dbt_charts/README.md` for details.
