# Contributing

If you'd like to add checks to flag new areas, please update this documentation and add an integration test.

## Adding a check

1. Add a SQL file named after the check (`fct_<what_is_checked>.sql`) in the folder of its category under `checks/` (`modeling`, `testing`, `documentation`, `structure`, `performance` or `governance`). The query returns one row per violation, with the resource to fix in the column `unique_id`, and no row when the check passes. Build it on the shared relations `evaluator_models()`, `evaluator_sources()` and `evaluator_edges()` from `macros/checks/` so that the exclusions (`exclude_packages`, `exclude_paths_from_project`) and the disabled resources are handled.
2. Describe it in the YAML file of the folder (`_<category>__checks.yml`). Add `selection_filter_on: none` to its `config` if it measures the whole project rather than individual resources.
3. Add the case it should flag to the project in `integration_tests_checks/` and the number of violations expected in `integration_tests_checks/expected_violations.csv`.
4. Document the rule in the page of its category under `docs/rules/` and in the [list of rules](rules.md).

## Running the integration tests

The checks run locally and don't need a warehouse. You need dbt `>=2.0.0` and then run

```bash
./integration_tests_checks/run_checks.sh
```

The script installs the package in the project `integration_tests_checks`, runs `dbt check` and compares the number of violations of each check with `expected_violations.csv`.

## Running docs locally

Docs are generated using [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/). To test them locally, run the following commands (use a Python virtual environment):

```bash
pip install mkdocs-material
mkdocs serve
```

Docs are then automatically pushed to the website as part of our CI/CD process. We use [mike](https://github.com/jimporter/mike) as part of the process to publish different versions of the docs.

Diagrams can be written as [Mermaid](https://mermaid.js.org/) charts in code blocks with the language `mermaid`, and are rendered by the site.

## Recommended VSCode extensions to help with writing docs

- [markdownlint](https://marketplace.visualstudio.com/items?itemName=DavidAnson.vscode-markdownlint)
    - Highlight issues with the Markdown code
    - The config used in `.vscode/settings.json` is the following:

        ```json
        "markdownlint.config": {
            "ul-indent": {"indent": 4},
            "MD036": false,
            "MD046": false,
        }
        ```

- [Mardown All in One](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one)
    - Makes it easy to paste links on top of text to create markdown links
