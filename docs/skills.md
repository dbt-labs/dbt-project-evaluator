# Agent skills

The package ships two agent skills (the AgentSkills format): instructions that a coding agent (Claude Code, Cursor, Codex...) loads when your request matches, so that it knows how to run, configure and migrate this package. dbt installs them into your project when you run `dbt deps`.

| Skill | Use it to |
| ----- | --------- |
| `using-dbt-project-evaluator` | run `dbt check`, read and fix the violations rule by rule, check only the resources you changed, set severity or disable a check, change thresholds, exclude packages or paths, [accept violations with exceptions](customization/exceptions.md) and run the checks in CI |
| `migrating-dbt-project-evaluator-to-v2` | migrate a project from version 1: it runs the [migration script](migrating-to-v2.md), converts the exceptions seed, helps you handle what could not be translated, updates the CI and verifies the result |

The skills contain no secret and run nothing by themselves: the agent follows them with the tools you give it, and asks you before accepting a violation.

## Install

1. Tell dbt which agent you use, in your `dbt_project.yml` (a single value or a list):

    ```yaml title="dbt_project.yml"
    flags:
      ai_provider: claude        # claude, cursor, codex, openai, gemini or wizard
    ```

    You can also pass it for one run: `dbt deps --ai-provider claude`.

2. Install or update the package, then run `dbt deps`:

    ```yaml title="packages.yml"
    packages:
      - package: dbt-labs/dbt_project_evaluator
        version: [">=2.0.0", "<3.0.0"]
    ```

    ```shell
    dbt deps
    ```

    dbt prints `Installing using-dbt-project-evaluator (dbt_project_evaluator) -> .claude/skills` for each skill.

Without `ai_provider`, `dbt deps` warns that it found skills and installs none.

dbt **copies** the skills (it does not link them): into `.claude/skills/` for Claude Code, and into `.agents/skills/` for the other agents. Every `dbt deps` brings the copies up to date with the installed version of the package. The copies are generated: do not edit them, and add them to your `.gitignore` like `dbt_packages/` if you prefer not to commit them. Skills that you wrote yourself in these folders are never touched.

## Turn them off

Disable all the skills of the package, or a single one, in your `dbt_project.yml`; the next `dbt deps` removes the copies that dbt installed:

```yaml title="dbt_project.yml"
skills:
  dbt_project_evaluator:
    +enabled: false                                  # all the skills of the package
    # or
    migrating-dbt-project-evaluator-to-v2:
      +enabled: false                                # just this one
```

## Use them

Ask your agent in plain words, for example "migrate this project to dbt_project_evaluator 2", "run the evaluator on the models I changed" or "accept the violation of `fct_root_models` for `dim_calendar`". The agent picks the matching skill from its description.
