# dbt_project_evaluator

> [!IMPORTANT]
> **Using dbt v1?** This README is for version 2, which requires dbt 2.0 or later. Stay on 1.x
> (see the [README of the `1.x` branch](https://github.com/dbt-labs/dbt-project-evaluator/blob/1.x/README.md))
> and cap the version in your `packages.yml` so that `dbt deps` doesn't upgrade you: `version: [">=1.0.0", "<2.0.0"]`

This package highlights areas of a dbt project that are misaligned with dbt Labs' best practices.
Specifically, it checks:

1. __[Modeling](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/modeling/)__ - your dbt DAG for modeling best practices
2. __[Testing](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/testing)__ - your models for testing best practices
3. __[Documentation](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/documentation)__ - your models for documentation best practices
4. __[Structure](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/structure)__ - your dbt project for file structure and naming best practices
5. __[Performance](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/performance)__ - your model materializations for performance best practices
6. __[Governance](https://dbt-labs.github.io/dbt-project-evaluator/latest/rules/governance)__ - your best practices for model governance features

Each rule is a native [dbt check](https://docs.getdbt.com/docs/build/checks): a SQL query over the dbt information schema that runs locally and returns one row per violation. Nothing is built in your warehouse, so it needs no credentials and works with every adapter supported by dbt 2.

## Why version 2?

- **Native.** Run the rules with `dbt check`, and configure them in `dbt_project.yml` like any other resource.
- **Checked before every build.** A rule set to `severity: error` stops a build that breaks it.
- **Fast.** About 15 seconds for a project of 1,900 models, against about 2 minutes for the 1.x `dbt build`.
- **Selectable.** `--select` and `state:modified` report only the violations on the resources you changed.
- **No warehouse needed.** No credentials and no compute cost, so CI needs no secrets.

## Install

```yaml
# packages.yml
packages:
  - package: dbt-labs/dbt_project_evaluator
    version: [">=2.0.0", "<3.0.0"]
```

The checks then run before every `dbt build`, and on demand with `dbt check`. They are advisory by default (`severity: warn`).

## Use

```shell
dbt check                                                       # every check
dbt check fct_root_models                                       # one check
dbt check --select state:modified --state path/to/main/target   # only what a pull request changes
```

Set the severity of a category or of a single check in your `dbt_project.yml`:

```yaml
checks:
  dbt_project_evaluator:
    structure:
      +severity: error          # block `dbt build` on violations
    documentation:
      fct_undocumented_models:
        +enabled: false         # turn off one rule
```

More options, in the documentation:

- [accept some violations as exceptions](https://dbt-labs.github.io/dbt-project-evaluator/latest/customization/exceptions/)
- [change a threshold or a naming convention](https://dbt-labs.github.io/dbt-project-evaluator/latest/customization/overriding-variables/)
- [exclude a package or a path](https://dbt-labs.github.io/dbt-project-evaluator/latest/customization/excluding-packages-and-paths/)
- [run the checks in CI](https://dbt-labs.github.io/dbt-project-evaluator/latest/ci-check/)

## Coming from version 1?

The rules are the same, but they are checks now instead of models, so the configuration changes: severity is set with `checks:`, exceptions are a var instead of a seed, and the 1.x tables are gone. `scripts/migrate_to_v2.py` converts your exceptions seed. See the [migration guide](https://dbt-labs.github.io/dbt-project-evaluator/latest/migrating-to-v2/) for all the changes.

## Agent skills

The package ships three skills that teach a coding agent (Claude Code, Cursor, Codex...) how to run the checks, fix the violations and migrate from 1.x. Set `ai_provider` under `flags:` in your `dbt_project.yml` and run `dbt deps` to install them. See [Agent skills](https://dbt-labs.github.io/dbt-project-evaluator/latest/skills/).

## Documentation

The rules, the configuration options, the exceptions and how to run the checks in CI are on [the documentation site](https://dbt-labs.github.io/dbt-project-evaluator/).
