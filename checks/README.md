# Native project checks

These checks reproduce 28 of the 29 dbt-project-evaluator rules using
parse-time dbt information-schema metadata. Each SQL file follows the native
checks contract: zero rows pass; returned rows are violations.
They default to `severity: warn`, matching the package's advisory behavior and
allowing ordinary `dbt build` invocations to continue after reporting findings.

## Implemented

- DAG: duplicate/unused sources, source/model fanout, multiple sources joined,
  direct joins to sources, root models, too many direct parents, rejoining
  upstream concepts, and layer-direction checks.
- Documentation and tests: undocumented models, source tables, and sources;
  aggregate documentation and test coverage; source freshness; primary-key
  test coverage; and test-directory parity.
- Governance: exposure parents must be public models, public models require
  contracts, and public model/column documentation coverage.
- Structure and performance: source/model directory placement, model naming
  conventions, chained views, and exposure parent materializations.

The existing evaluator variables remain the configuration surface for
thresholds and conventions, including `models_fanout_threshold`,
`too_many_joins_threshold`, `chained_views_threshold`,
`documentation_coverage_target`, `test_coverage_target`,
`primary_key_test_macros`, model folders, and model prefixes.

## Deferred

- `fct_hard_coded_references` requires parsed SQL or lint/static-analysis
  findings. It is intentionally not approximated with raw string matching at
  parse time.

Package and path exclusions are supported. Row-level exceptions from the
`dbt_project_evaluator_exceptions` seed remain future work because native
parse-time checks do not execute or depend on warehouse seed relations.
