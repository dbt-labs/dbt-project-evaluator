# Contributing

If you'd like to add models to flag new areas, please update this documentation and add an integration test
([more details here](https://github.com/dbt-labs/pro-serv-dag-auditing/tree/main/integration_tests#adding-an-integration-test))

## Running docs locally

Docs are generated using [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/). To test them locally, run the following commands (use a Python virtual environment):

```bash
pip install mkdocs-material
mkdocs serve
```

Docs are then automatically pushed to the website as part of our CI/CD process. We use [mike](https://github.com/jimporter/mike) as part of the process to publish different versions of the docs.

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
