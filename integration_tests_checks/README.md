# Fixtures for the native checks

`./run_checks.sh` (needs dbt v2 on PATH, runs on DuckDB, no credentials) runs `dbt check` on each project below and compares the number of violations per check with the project's `expected_violations.csv`.

| Project | What it covers |
|---|---|
| `violations/` | One small project that breaks every rule on purpose, plus regression cases for things that must be ignored or counted correctly: a disabled model, source table and test, a singular test, sources whose only consumers are tests, a snapshot joining two sources. |
| `parity_1x/` | The 1.x `integration_tests` project: its DAG, `exclude_package`, exclusion vars, thresholds and a custom `new_model_type`, versioned models, exposures, metrics and custom generic tests. |
| `parity_1x_no_exposures/` | The 1.x `integration_tests_2` project: no exposures, no metrics, a custom `primary_key_test_macros`. Every check must still run. |
| `parity_1x_semantic_layer/` | The 1.x `integration_tests_sl` project: same DAG with the new semantic layer YAML. |

## Where the `parity_*` expectations come from

In 1.x each rule was compared, row by row, with an expected-output seed. When these projects were ported, the resources flagged by each check were compared with those seeds, with the differences below. `dbt check` only prints the first five rows of a check, so what is committed and re-checked on every run is the number of violations.

| Check | Expected here | Why it differs from the 1.x seed |
|---|---|---|
| `fct_missing_primary_key_tests` | one more model than 1.x (`dim_model_7`) | 1.x counts a `not_null` constraint. Constraints are not available to checks. |
| `fct_duplicate_sources` | one row per source of a group | 1.x returned one row per group. |
| `fct_undocumented_sources` | one row per source | same as 1.x |
| `fct_hard_coded_references`, exceptions seed | not covered | not part of v2 |

The 1.x `*_schema_tests` models (tests of the package's internal models) have no equivalent because those models no longer exist.
