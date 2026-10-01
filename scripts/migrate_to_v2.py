#!/usr/bin/env python3
"""Help a project move from dbt_project_evaluator 1.x to 2.x.

* converts the 1.x exceptions seed (`dbt_project_evaluator_exceptions.csv`) into the 2.x
  `dbt_project_evaluator_exceptions` mapping, as a macro file or a `vars:` snippet
* prints a checklist of the 1.x leftovers found in the project (dbt_project.yml, packages,
  CI files, models referencing removed models)

Python 3 standard library only. Nothing is changed in the project except the file written by
`--output` (never overwritten without `--force`).

    python dbt_packages/dbt_project_evaluator/scripts/migrate_to_v2.py                       # convert the seed + checklist
    python dbt_packages/dbt_project_evaluator/scripts/migrate_to_v2.py --check-only          # checklist only
    python dbt_packages/dbt_project_evaluator/scripts/migrate_to_v2.py --format var          # YAML snippet for `vars:` on stdout

Use `python3` instead of `python` if `python` is not found (macOS, Linux), `py` on Windows, or
`uv run dbt_packages/dbt_project_evaluator/scripts/migrate_to_v2.py` anywhere.
"""
import argparse
import csv
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------------------------
# Exceptions: how a 1.x row (fct model, column, pattern) is written in 2.x.
#
# A 2.x entry is either a string, matched against the name or unique_id of the resource the
# violation points at (the `unique_id` column of the check), or a mapping {column: pattern} on a
# column returned by the check. The columns of the 1.x fct_ models are mapped one by one:
#   S             -> a string entry (the 1.x column is the resource the 2.x violation points at)
#   C(col)        -> an entry {col: pattern} (the column exists in 2.x, possibly under another name)
#   R(reason)     -> cannot be translated: written as a NEEDS REVIEW comment
# ---------------------------------------------------------------------------------------------
S = ("string",)


def C(column, note="", also=()):
    return ("column", column, note, tuple(also))


def R(reason):
    return ("review", reason)


LIST_NOTE = "a list in 2.x: matches when any element matches"


def gone(what="the 2.x check no longer returns it"):
    return R(what)


TRANSLATION = {
    "fct_chained_views_dependencies": {
        "child": S, "parent": C("parent"), "distance": C("distance"),
        "path": gone("the path is not returned in 2.x: use the `child` and `parent` columns"),
    },
    "fct_direct_join_to_source": {
        "child": S,
        # 1.x had one row per parent (source or model); 2.x has one row per child with the lists
        "parent": C("source_parents", "drops the violation of a child as soon as one of its parents matches", also=("model_parents",)),
        "parent_resource_type": gone("2.x lists the source parents and the model parents in separate columns"),
        "child_resource_type": gone("always a model in 2.x"),
        "distance": gone("always 1: direct parents only"),
    },
    "fct_duplicate_sources": {
        "source_names": C("source_name", "1.x had one row per group: each source of the group is its own row in 2.x, so every source of the group needs to match"),
        "source_db_location": gone("2.x has `source_relation` (lower case, not quoted, database.schema.identifier): rewrite the pattern on that column"),
    },
    "fct_exposure_parents_materializations": {
        "exposure_name": S, "parent_resource_name": C("parent_resource_name"),
        "parent_resource_type": C("parent_resource_type"), "parent_model_materialization": C("parent_model_materialization"),
    },
    "fct_exposures_dependent_on_private_models": {
        "exposure_name": S, "parent_resource_name": C("parent_resource_name"),
        "parent_resource_type": C("parent_resource_type"), "parent_access": C("parent_access"),
    },
    "fct_marts_or_intermediate_dependent_on_source": {
        "child": S, "parent": C("source_name"), "child_model_type": C("model_type"),
        "parent_resource_type": gone("always a source in 2.x"),
    },
    "fct_missing_primary_key_tests": {
        "resource_name": S, "resource_type": C("resource_type"),
        "model_type": gone(), "is_primary_key_tested": gone("always false for a violation"),
        "number_of_tests_on_model": gone(), "number_of_constraints_on_model": gone("constraints are not counted in 2.x"),
    },
    "fct_model_directories": {
        "resource_name": S, "model_type": C("model_type"), "current_file_path": C("current_file_path"),
        "change_file_path_to": C("change_file_path_to"), "resource_type": gone("always a model in 2.x"),
    },
    "fct_model_fanout": {
        "parent": S, "leaf_children": C("leaf_children", LIST_NOTE), "parent_model_type": gone(),
    },
    "fct_model_naming_conventions": {
        "resource_name": S, "model_type": C("model_type"), "appropriate_prefixes": C("appropriate_prefixes"),
        "prefix": gone("2.x reports the prefixes the model should have, not the one it has"),
    },
    "fct_multiple_sources_joined": {
        "child": S, "source_parents": C("source_parents", LIST_NOTE),
    },
    "fct_public_models_without_contract": {
        "resource_name": S, "is_contract_enforced": C("contract_enforced"),
        "is_public": gone("2.x returns `access`, which is always public here"),
    },
    "fct_rejoining_of_upstream_concepts": {
        "parent_and_child": S, "parent": C("parent"), "child": C("child"),
        "is_loop_independent": gone(),
    },
    "fct_root_models": {"child": S},
    "fct_source_directories": {
        "resource_name": S, "current_file_path": C("current_file_path"), "change_file_path_to": C("change_file_path_to"),
        "resource_type": gone("always a source in 2.x"),
    },
    "fct_source_fanout": {
        "parent": S, "model_children": C("model_children", LIST_NOTE),
    },
    "fct_sources_without_freshness": {"resource_name": S},
    "fct_staging_dependent_on_marts_or_intermediate": {
        "child": S, "parent": C("parent"), "parent_model_type": C("parent_model_type"),
        "child_model_type": gone("always staging in 2.x"),
    },
    "fct_staging_dependent_on_staging": {
        "child": S, "parent": C("parent"),
        "child_model_type": gone("always staging in 2.x"), "parent_model_type": gone("always staging in 2.x"),
    },
    "fct_test_directories": {
        "model_name": S, "change_test_directory_to": C("change_properties_yml_directory_to"),
        "current_test_directory": gone("2.x returns the path of the properties YAML file (`current_properties_yml_file_path`), not its directory: rewrite the pattern"),
        "test_name": gone("2.x reports one row per model, not per test"),
    },
    "fct_too_many_joins": {
        "resource_name": S,
        "join_count": gone("2.x counts the direct parents (`parent_count`), not the joins of the SQL: not the same measure"),
        "file_path": gone(),
    },
    "fct_undocumented_models": {"resource_name": S, "model_type": gone()},
    "fct_undocumented_public_models": {
        "resource_name": S, "is_described": C("is_described_model"),
        "total_defined_columns": C("total_defined_columns"), "total_described_columns": C("total_described_columns"),
        "access": gone("always public in 2.x"),
    },
    "fct_undocumented_source_tables": {"resource_name": S},
    "fct_undocumented_sources": {"source_name": C("source_name")},
    "fct_unused_sources": {"parent": S},
}

# columns returned by the 2.x checks (for the message when a column does not exist any more)
V2_COLUMNS = {
    "fct_chained_views_dependencies": "child, parent, distance",
    "fct_direct_join_to_source": "name, source_parents, model_parents",
    "fct_duplicate_sources": "source_name, source_relation",
    "fct_exposure_parents_materializations": "exposure_name, parent_resource_type, parent_resource_name, parent_model_materialization",
    "fct_exposures_dependent_on_private_models": "exposure_name, parent_unique_id, parent_resource_name, parent_resource_type, parent_access",
    "fct_marts_or_intermediate_dependent_on_source": "name, model_type, source_name",
    "fct_missing_primary_key_tests": "name, resource_type",
    "fct_model_directories": "name, model_type, current_file_path, change_file_path_to",
    "fct_model_fanout": "name, leaf_children",
    "fct_model_naming_conventions": "name, model_type, appropriate_prefixes, original_file_path",
    "fct_multiple_sources_joined": "name, source_parents",
    "fct_public_models_without_contract": "name, access, contract_enforced",
    "fct_rejoining_of_upstream_concepts": "parent, parent_and_child, child",
    "fct_root_models": "name, original_file_path",
    "fct_source_directories": "source_name, current_file_path, change_file_path_to",
    "fct_source_fanout": "source_name, model_children",
    "fct_sources_without_freshness": "source_name",
    "fct_staging_dependent_on_marts_or_intermediate": "name, parent, parent_model_type",
    "fct_staging_dependent_on_staging": "name, parent",
    "fct_test_directories": "model_name, current_properties_yml_file_path, change_properties_yml_directory_to",
    "fct_too_many_joins": "name, parent_count",
    "fct_undocumented_models": "name, original_file_path",
    "fct_undocumented_public_models": "name, is_described_model, total_defined_columns, total_described_columns",
    "fct_undocumented_source_tables": "source_name, original_file_path",
    "fct_undocumented_sources": "source_name, original_file_path",
    "fct_unused_sources": "source_name, original_file_path",
}

NOT_APPLICABLE = {
    "fct_hard_coded_references": "the rule is not a check in 2.x any more: hard-coded references are reported by `dbt lint` (rule DBT05), see the migration guide",
    "fct_documentation_coverage": "coverage rules are project-wide metrics and never supported exceptions; use the documentation_coverage_target var",
    "fct_test_coverage": "coverage rules are project-wide metrics and never supported exceptions; use the test_coverage_target var",
}

JINJA_OPENERS = ("{{", "{%", "{#")


def norm(value):
    return (value or "").strip()


def safe_text(text):
    """Text for a YAML comment inside a Jinja block: one line, no Jinja delimiters."""
    return re.sub(r"\s+", " ", text or "").strip().replace("{", "(").replace("}", ")")


def yaml_quote(value):
    return "'" + value.replace("'", "''") + "'"


def one_line_comment(text):
    return safe_text(text)


# ---------------------------------------------------------------------------------------------
# Seed -> 2.x mapping
# ---------------------------------------------------------------------------------------------
def find_seed(project_dir):
    skip = {"dbt_packages", "dbt_internal_packages", "target", "logs", ".git", "node_modules", "site"}
    found = []
    for path in sorted(project_dir.rglob("dbt_project_evaluator_exceptions.csv")):
        if not skip & set(path.relative_to(project_dir).parts):
            found.append(path)
    return found


def convert_rows(rows):
    """Returns (translated {fct: [(entry, comment, note)]}, review [(row_no, line, reason)], na [(row_no, line, reason)]).

    An entry is ("string", pattern) or ("column", column, pattern).
    """
    translated, review, na = {}, [], []
    for number, row in enumerate(rows, start=2):  # row 1 is the header
        row = {(k or "").strip().lower(): v for k, v in row.items()}
        fct, column, pattern = norm(row.get("fct_name")).lower(), norm(row.get("column_name")).lower(), norm(row.get("id_to_exclude"))
        comment = one_line_comment(row.get("comment"))
        original = safe_text(f"{fct} / {column} / {pattern!r}" + (f" ({comment})" if comment else ""))
        if not fct and not column and not pattern:
            continue
        if fct in NOT_APPLICABLE:
            na.append((number, original, NOT_APPLICABLE[fct]))
            continue
        if fct not in TRANSLATION:
            review.append((number, original, f"'{fct}' is not a rule of dbt_project_evaluator 2.x (typo, or a rule that was removed)"))
            continue
        if not pattern:
            review.append((number, original, "empty id_to_exclude"))
            continue
        if any(token in pattern for token in JINJA_OPENERS) or "\n" in pattern:
            review.append((number, original, "the pattern contains Jinja delimiters or a line break and cannot be written safely in a macro"))
            continue
        columns = TRANSLATION[fct]
        if column not in columns:
            review.append((number, original, f"'{column}' is not a column of {fct} in 1.x"))
            continue
        rule = columns[column]
        if rule[0] == "review":
            review.append((number, original, f"{rule[1]} (2.x returns: {V2_COLUMNS[fct]})"))
        elif rule[0] == "string":
            translated.setdefault(fct, []).append((("string", pattern), comment, ""))
        else:
            _, v2_column, note, also = rule
            for n, target in enumerate((v2_column,) + also):
                translated.setdefault(fct, []).append((("column", target, pattern), comment if n == 0 else "", note if n == 0 else ""))
    return translated, review, na


def render_entry(entry):
    if entry[0] == "string":
        return yaml_quote(entry[1])
    return "{" + entry[1] + ": " + yaml_quote(entry[2]) + "}"


def render_mapping(translated, review, na, indent, source_name):
    """YAML lines (a mapping + comments) at the given indentation."""
    pad = " " * indent
    lines = []
    for fct in sorted(translated):
        lines.append(f"{pad}{fct}:")
        seen = set()
        for entry, comment, note in translated[fct]:
            if entry in seen:
                continue
            seen.add(entry)
            trailing = " ".join(part for part in (comment, f"[{safe_text(note)}]" if note else "") if part)
            lines.append(f"{pad}  - {render_entry(entry)}" + (f"   # {trailing}" if trailing else ""))
    if review:
        lines += ["", f"{pad}# NEEDS REVIEW: 1.x exceptions that could not be translated automatically.",
                  f"{pad}# 2.x entries are a pattern on the resource a violation points at, or a mapping (column: pattern) on a column of the check."]
        for number, original, reason in review:
            lines.append(f"{pad}# {source_name}:{number}: {original}")
            lines.append(f"{pad}#     -> {safe_text(reason)}")
    if na:
        lines += ["", f"{pad}# NOT APPLICABLE in 2.x (dropped on purpose):"]
        for number, original, reason in na:
            lines.append(f"{pad}# {source_name}:{number}: {original}")
            lines.append(f"{pad}#     -> {reason}")
    return lines


def render_macro(translated, review, na, source_name):
    body = render_mapping(translated, review, na, 0, source_name)
    return "\n".join(
        [
            "{# Generated by migrate_to_v2.py from " + source_name + ". Violations of dbt_project_evaluator checks that this project accepts. #}",
            "{% macro default__dbt_project_evaluator_exceptions() %}",
            "{% set exceptions %}",
            *body,
            "{% endset %}",
            "{{ return(fromyaml(exceptions)) }}",
            "{% endmacro %}",
            "",
        ]
    )


def render_var(translated, review, na, source_name):
    body = render_mapping(translated, review, na, 4, source_name)
    return "\n".join(
        ["# Generated by migrate_to_v2.py from " + source_name, "vars:", "  dbt_project_evaluator_exceptions:", *(body or ["    {}"]), ""]
    )


# ---------------------------------------------------------------------------------------------
# Checklist of 1.x leftovers
# ---------------------------------------------------------------------------------------------
REMOVED_VARS = ["insert_batch_size", "max_depth_dag", "comment_chars", "token_costs", "use_native_agate_printing"]
V1_MODELS = [
    "int_all_dag_relationships", "int_all_graph_resources", "int_direct_relationships", "int_model_test_summary",
    "base_exposure_relationships", "base_metric_relationships", "base_node_columns", "base_node_relationships", "base_source_columns",
    "stg_columns", "stg_exposure_relationships", "stg_exposures", "stg_metric_relationships", "stg_metrics", "stg_naming_convention_folders",
    "stg_naming_convention_prefixes", "stg_node_relationships", "stg_nodes", "stg_sources",
    "dbt_project_evaluator_exceptions",
] + sorted(set(TRANSLATION) | {"fct_hard_coded_references", "fct_documentation_coverage", "fct_test_coverage"})
SKIP_DIRS = {"dbt_packages", "dbt_internal_packages", "target", "logs", ".git", "node_modules", "site", "venv", ".venv", "dbt_modules"}
CI_SUFFIXES = {".yml", ".yaml", ".sh", ".toml", ".cfg", ".ini"}
CI_NAMES = {"Makefile", "Dockerfile", ".env", "tox.ini"}
REGEXY = re.compile(r"\.\*|\.\+|\\|\^|\$|\[|\]|\(|\)|\||\+|\?|\{")


class Finding:
    def __init__(self, where, what, fix, info=False):
        self.where, self.what, self.fix, self.info = where, what, fix, info


def indent_of(line):
    return len(line) - len(line.lstrip(" "))


def strip_comment(line):
    in_s = in_d = False
    for i, ch in enumerate(line):
        if ch == "'" and not in_d:
            in_s = not in_s
        elif ch == '"' and not in_s:
            in_d = not in_d
        elif ch == "#" and not in_s and not in_d and (i == 0 or line[i - 1] in " \t"):
            return line[:i]
    return line


def top_level_sections(lines):
    """{key: (start_index, end_index)} of the top-level keys of a YAML file (line scanner, no PyYAML)."""
    starts = []
    for i, line in enumerate(lines):
        if line.strip() and not line.startswith((" ", "\t", "#", "-")) and ":" in line:
            starts.append((line.split(":", 1)[0].strip(), i))
    return {key: (start, starts[n + 1][1] if n + 1 < len(starts) else len(lines)) for n, (key, start) in enumerate(starts)}


def scalar_items(lines, start):
    """Values of a list or inline list given under `key:` at lines[start] (strings, quotes removed)."""
    head = strip_comment(lines[start]).split(":", 1)[1].strip()
    items = []
    if head.startswith("["):
        text = head
        j = start
        while "]" not in text and j + 1 < len(lines):
            j += 1
            text += strip_comment(lines[j])
        inner = text[text.index("[") + 1: text.rindex("]")] if "]" in text else text[1:]
        items = [part.strip().strip("'\"") for part in re.split(r",(?=(?:[^'\"]|'[^']*'|\"[^\"]*\")*$)", inner) if part.strip()]
    elif head:
        items = [head.strip("'\"")]
    else:
        base = indent_of(lines[start])
        for j in range(start + 1, len(lines)):
            raw = strip_comment(lines[j])
            if not raw.strip():
                continue
            if indent_of(raw) <= base and not raw.lstrip().startswith("-"):
                break
            if raw.lstrip().startswith("-"):
                items.append(raw.lstrip()[1:].strip().strip("'\""))
            else:
                break
    return items


def check_dbt_project(path, findings):
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    rel = path.name
    sections = top_level_sections(lines)

    for i, line in enumerate(lines, start=1):
        if "print_dbt_project_evaluator_issues" in line and not line.lstrip().startswith("#"):
            findings.append(Finding(f"{rel}:{i}", "on-run-end hook printing the 1.x issues",
                                    "Delete it: `dbt check` and `dbt build` report violations themselves"))

    for key in ("models", "seeds", "tests", "data_tests", "snapshots"):
        if key in sections:
            start, end = sections[key]
            for i in range(start + 1, end):
                if re.match(r"^  dbt_project_evaluator:\s*(#.*)?$", lines[i]):
                    if key in ("tests", "data_tests"):
                        fix = ("Delete it. Severity is now set per category or per check: "
                               "`checks: {dbt_project_evaluator: {<category>: {+severity: error}}}`")
                    elif key == "seeds":
                        fix = "Delete it: the exceptions seed no longer exists (see the exceptions step)"
                    else:
                        fix = "Delete it: the package has no models to materialize any more"
                    findings.append(Finding(f"{rel}:{i + 1}", f"`{key}: dbt_project_evaluator:` configuration for 1.x", fix))

    if "dispatch" in sections:
        start, end = sections["dispatch"]
        for i in range(start + 1, end):
            if "dbt_project_evaluator" in lines[i] and not lines[i].lstrip().startswith("#"):
                findings.append(Finding(f"{rel}:{i + 1}", "`dispatch` entry for dbt_project_evaluator (1.x cross-database macros)",
                                        "Delete the entry (or the whole `dispatch` block if nothing else uses it)"))

    if "vars" in sections:
        start, end = sections["vars"]
        for i in range(start + 1, end):
            m = re.match(r"^\s+([A-Za-z_][\w]*)\s*:", lines[i])
            if not m:
                continue
            name = m.group(1)
            if name in REMOVED_VARS:
                findings.append(Finding(f"{rel}:{i + 1}", f"var `{name}` no longer exists", "Delete it"))
            elif name == "exclude_paths_from_project":
                items = scalar_items(lines, i)
                regexy = [item for item in items if REGEXY.search(item)]
                if regexy:
                    findings.append(Finding(f"{rel}:{i + 1}", "`exclude_paths_from_project` entries look like regular expressions: " + ", ".join(repr(p) for p in regexy),
                                            "2.x matches a literal substring (SQL LIKE '%…%', case-sensitive; `%` and `_` are wildcards): "
                                            "rewrite each entry as plain text, one entry per path"))
                if items:
                    findings.append(Finding(f"{rel}:{i + 1}", "`exclude_paths_from_project` is used",
                                            "2.x applies it to every package (not only this project), is case-sensitive, and also matches the resource's unique_id", info=True))
            elif name == "dbt_project_evaluator_exceptions":
                pass


def read_text(path):
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def iter_files(project_dir, predicate):
    for path in sorted(project_dir.rglob("*")):
        if path.is_file() and not (SKIP_DIRS & set(path.relative_to(project_dir).parts)) and predicate(path):
            yield path


def check_project(project_dir):
    findings = []
    dbt_project = project_dir / "dbt_project.yml"
    if dbt_project.exists():
        check_dbt_project(dbt_project, findings)
    else:
        findings.append(Finding(str(project_dir), "no dbt_project.yml found", "Run the script from the root of your dbt project or pass --project-dir"))

    for name in ("packages.yml", "dependencies.yml"):
        path = project_dir / name
        if not path.exists():
            continue
        lines = read_text(path).splitlines()
        for i, line in enumerate(lines):
            if re.search(r"dbt[-_]labs/dbt_project_evaluator|dbt_project_evaluator", line) and "package" in line:
                window = " ".join(lines[i: i + 3])
                if not re.search(r">=\s*2\.", window):
                    findings.append(Finding(f"{name}:{i + 1}", "dbt_project_evaluator is not pinned to 2.x",
                                            'Use `version: [">=2.0.0", "<3.0.0"]` (dbt >= 2.0.0 only; dbt Core projects stay on `[">=1.0.0", "<2.0.0"]`)'))

    patterns = [
        (re.compile(r"print_dbt_project_evaluator_issues"), "calls the 1.x on-run-end printer", "Remove it: `dbt check`/`dbt build` print the violations"),
        (re.compile(r"DBT_PROJECT_EVALUATOR_SEVERITY"), "uses the DBT_PROJECT_EVALUATOR_SEVERITY env var", "Set the severity with `checks: {dbt_project_evaluator: {+severity: error}}`"),
        (re.compile(r"package:dbt_project_evaluator"), "selects or excludes the package's models", "Use `dbt check` (and `--select state:modified`, with `--state <dir>` outside the dbt platform); drop the package from selectors/excludes"),
        (re.compile(r"^\s*(?:-\s*)?value:\s*['\"]?dbt_project_evaluator['\"]?\s*(?:#.*)?$"), "selector on the package's models (`method: package`)", "Drop it from selectors.yml: 2.x has no models to select or exclude"),
        (re.compile(r"dbt_project_evaluator_exceptions"), "references the exceptions seed", "Remove it after converting the seed into the exceptions mapping"),
    ]
    for path in iter_files(project_dir, lambda p: p.suffix in CI_SUFFIXES or p.name in CI_NAMES):
        if path.name == "dbt_project.yml" and path.parent == project_dir:
            continue
        for i, line in enumerate(read_text(path).splitlines(), start=1):
            if line.lstrip().startswith("#"):
                continue
            for regex, what, fix in patterns:
                if regex.search(line):
                    findings.append(Finding(f"{path.relative_to(project_dir).as_posix()}:{i}", what, fix))

    ref_regex = re.compile(r"""(?:ref)\(\s*['"](?:dbt_project_evaluator['"]\s*,\s*['"])?(%s)['"]""" % "|".join(map(re.escape, V1_MODELS)))
    for path in iter_files(project_dir, lambda p: p.suffix == ".sql"):
        for i, line in enumerate(read_text(path).splitlines(), start=1):
            m = ref_regex.search(line)
            if m:
                findings.append(Finding(f"{path.relative_to(project_dir).as_posix()}:{i}", f"refs `{m.group(1)}`, a 1.x model that no longer exists",
                                        "Query the information schema instead (`{{ info_schema('edges') }}`...), see the 'Querying the DAG' page"))
    return findings


def print_checklist(findings, out):
    if not findings:
        print("No 1.x leftovers found.", file=out)
        return
    findings = sorted(findings, key=lambda f: (f.info, f.where.split(":")[0], int(f.where.split(":")[1]) if ":" in f.where and f.where.split(":")[1].isdigit() else 0))
    print(f"{len(findings)} thing(s) to check ([i] = for information):\n", file=out)
    for finding in findings:
        print(f"[{'i' if finding.info else ' '}] {finding.where}: {finding.what}\n      -> {finding.fix}", file=out)


# ---------------------------------------------------------------------------------------------
def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project-dir", default=".", help="root of the dbt project (default: .)")
    parser.add_argument("--exceptions-csv", help="1.x exceptions seed (default: auto-detect seeds/**/dbt_project_evaluator_exceptions.csv)")
    parser.add_argument("--format", choices=["macro", "var"], default="macro", help="how to write the exceptions (default: macro)")
    parser.add_argument("--output", help="file to write ('-' for stdout). Default: macros/dbt_project_evaluator_exceptions.sql for macro, stdout for var")
    parser.add_argument("--force", action="store_true", help="overwrite the output file if it exists")
    parser.add_argument("--check-only", action="store_true", help="only print the checklist of 1.x leftovers")
    args = parser.parse_args(argv)

    # the messages and the generated files contain non-ASCII characters: never fail on a console
    # (Windows code pages) or a pipe that is not UTF-8
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")

    project_dir = Path(args.project_dir).resolve()
    status = 0

    if not args.check_only:
        csv_path = Path(args.exceptions_csv) if args.exceptions_csv else None
        if csv_path is None:
            seeds = find_seed(project_dir)
            if len(seeds) > 1:
                print("Several exceptions seeds found, pass one with --exceptions-csv:\n  " + "\n  ".join(map(str, seeds)), file=sys.stderr)
                return 2
            csv_path = seeds[0] if seeds else None
        if csv_path is None:
            print("No dbt_project_evaluator_exceptions.csv found: nothing to convert.\n", file=sys.stderr)
        elif not csv_path.exists():
            print(f"{csv_path} does not exist", file=sys.stderr)
            return 2
        else:
            with csv_path.open(newline="", encoding="utf-8-sig") as handle:
                rows = list(csv.DictReader(handle))
            translated, review, na = convert_rows(rows)
            try:
                source_name = csv_path.resolve().relative_to(project_dir).as_posix()
            except ValueError:
                source_name = csv_path.name
            render = render_macro if args.format == "macro" else render_var
            text = render(translated, review, na, source_name)
            output = args.output or (str(project_dir / "macros" / "dbt_project_evaluator_exceptions.sql") if args.format == "macro" else "-")
            count = sum(1 for row in rows if any((value or '').strip() for value in row.values())) - len(review) - len(na)
            if output == "-":
                sys.stdout.write(text + "\n")
                log = sys.stderr
            else:
                target = Path(output)
                if target.exists() and not args.force:
                    print(f"{target} already exists (use --force to overwrite)", file=sys.stderr)
                    return 2
                target.parent.mkdir(parents=True, exist_ok=True)
                with target.open("w", encoding="utf-8", newline="\n") as handle:
                    handle.write(text)
                log = sys.stdout
                print(f"Wrote {target}", file=log)
            print(f"Exceptions: {count} translated, {len(review)} to review by hand, {len(na)} not applicable ({csv_path.name}, {len(rows)} rows)", file=log)
            if review:
                print("Lines marked NEEDS REVIEW were not translated: check them one by one.", file=log)
                status = 0
            print("", file=log)

    print_checklist(check_project(project_dir), sys.stdout if not (args.output == "-" or (not args.check_only and args.format == "var" and not args.output)) else sys.stderr)
    return status


if __name__ == "__main__":
    sys.exit(main())
