---
name: fixing-dbt-project-evaluator-violations
description: Use when the user wants to fix, clear or reduce the violations that `dbt check` reports for dbt_project_evaluator version 2 (the fct_* checks), for example "fix the undocumented models", "get the evaluator to pass", "clean up the structure violations", "add the missing primary key tests", "add freshness to the sources", "refactor the models that read from sources" or "reduce the chained views". It is a fix-and-verify loop by check and category, with recipes. Do not use to run the package, change severity, thresholds or exclusions, or accept a violation as an exception (use using-dbt-project-evaluator), nor to migrate from version 1 (use migrating-dbt-project-evaluator-to-v2).
---

# Fixing dbt_project_evaluator violations

Each row a check returns points, in its `unique_id` column, at the resource to fix. Work in small steps: pick one check, fix its resources, prove with a scoped re-run that the count dropped by exactly what you fixed.

## 1. Baseline

```shell
dbt --version            # 2.0.0 or later; dbt Core 1.x runs version 1 of the package, which this skill does not cover
dbt check                # every check, whole project
```

Summarize for the user: violations per category and per check, from the lines `check 'x' found with N violation(s)` (`warn`) or `failed with N violation(s)` (`error`). The category of a check is in [references/checks.md](references/checks.md), which also says which fixes are safe and which need judgement. Ask which category or check to start with if the user did not say.

## 2. Choose a scope

- One check: `dbt check fct_undocumented_models`. One folder or resource: `--select staging`, `--select path:models/marts`, `--select stg_orders`.
- Only the **first 5 rows** of a check are printed. To see them all, narrow with `--select` (folder by folder) until fewer than 5 rows show, or read the count and fix 5 at a time, re-running between rounds.
- The checks that report **sources** (`fct_unused_sources`, `fct_sources_without_freshness`, `fct_undocumented_source_tables`, `fct_undocumented_sources`, `fct_duplicate_sources`, `fct_source_directories`, `fct_source_fanout`) cannot be scoped by `--select` (dbt-labs/dbt#16554): run them without a selector.
- `fct_documentation_coverage` and `fct_test_coverage` are project-wide: they ignore `--select` and drop out when the target is reached; fix the per-resource checks to raise them.

## 3. Order of work

1. **Safe, additive**: descriptions, primary key tests, source freshness, contracts, public access. They change no SQL and no relation.
2. **Structure**: moving files, renaming models. They change paths, names and refs.
3. **Modeling and performance**: staging models, splitting or folding models, materializations. They change the DAG and need the user's judgement.

## 4. The loop, for one check

1. Read the rows and the rule's explanation: `dbt_packages/dbt_project_evaluator/docs/rules/<category>.md` (modeling, testing, documentation, structure, performance, governance). The recipe for the check is in [references/playbooks.md](references/playbooks.md).
2. Fix the resource named in `unique_id`, not a neighbour of it.
3. Verify:
   - `dbt check <check> --select <resource or folder>`: the count must drop by what you fixed, and no new row may appear.
   - After a rename or a move, `dbt parse` must succeed (refs, exposures, tests, `meta`), then run the whole `dbt check` once: a move or a rename can create or clear violations in other checks.
4. Repeat until the check is clean, then tell the user the before and after counts.

Commit one check, or one folder, at a time so that a change that breaks something can be reverted alone.

## Guardrails

- **Ask before** bulk renames, moves or refactors that touch many files or that downstream consumers see: a renamed model changes its relation name for BI tools, other projects and exposures. When renaming, keep the relation with `{{ config(alias='old_name') }}` unless the user wants the new name in the warehouse.
- **Never silence a violation**: no exception, no `+enabled: false`, no higher threshold, no lower severity, unless the user asks for it or says the violation is intentional. Then use the using-dbt-project-evaluator skill.
- Fix what the rule says, not what makes the number go down: a one-word description to clear `fct_undocumented_models` is not a fix. Write a description a colleague could use, or ask the user for the content.
- Do not guess business meaning. If a description, a grain or a reason cannot be read from the code, ask.
- Known limitations: `fct_missing_primary_key_tests` does not count `not_null` constraints yet (dbt-labs/dbt#16553), so add the test as well; hard-coded references are reported by `dbt lint` (rule `DBT05`), not by a check.

## Finish

Run `dbt check` once more, give the user the before and after counts per check, and list what is left and why (needs a decision, intentional, limitation).
