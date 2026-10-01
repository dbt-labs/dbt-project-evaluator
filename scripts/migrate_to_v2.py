#!/usr/bin/env python3
"""Help a project move from dbt_project_evaluator 1.x to 2.x.

* converts the 1.x exceptions seed (`dbt_project_evaluator_exceptions.csv`) into the 2.x
  `dbt_project_evaluator_exceptions` mapping, as a macro file or a `vars:` snippet
* prints a checklist of the 1.x leftovers found in the project (dbt_project.yml, packages,
  CI files, models referencing removed models)

Python 3 standard library only. Nothing is changed in the project except the file written by
`--output` (never overwritten without `--force`).

    python3 scripts/migrate_to_v2.py                      # convert the seed + checklist
    python3 scripts/migrate_to_v2.py --check-only         # checklist only
    python3 scripts/migrate_to_v2.py --format var         # YAML snippet for `vars:` on stdout
"""
import argparse
import csv
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------------------------
# Exceptions: which 1.x column identifies the resource a 2.x violation points at.
#
# A 2.x exception is a pattern matched against the name (or unique_id) of the resource that the
# `unique_id` column of the violation points at. A 1.x exception on another column of the fct_
# model cannot be expressed, so it is never translated automatically.
# ---------------------------------------------------------------------------------------------
RESOURCE_COLUMN = {
    "fct_chained_views_dependencies": "child",
    "fct_direct_join_to_source": "child",
    "fct_duplicate_sources": None,
    "fct_exposure_parents_materializations": "exposure_name",
    "fct_exposures_dependent_on_private_models": "exposure_name",
    "fct_marts_or_intermediate_dependent_on_source": "child",
    "fct_missing_primary_key_tests": "resource_name",
    "fct_model_directories": "resource_name",
    "fct_model_fanout": "parent",
    "fct_model_naming_conventions": "resource_name",
    "fct_multiple_sources_joined": "child",
    "fct_public_models_without_contract": "resource_name",
    "fct_rejoining_of_upstream_concepts": "parent_and_child",
    "fct_root_models": "child",
    "fct_source_directories": "resource_name",
    "fct_source_fanout": "parent",
    "fct_sources_without_freshness": "resource_name",
    "fct_staging_dependent_on_marts_or_intermediate": "child",
    "fct_staging_dependent_on_staging": "child",
    "fct_test_directories": "model_name",
    "fct_too_many_joins": "resource_name",
    "fct_undocumented_models": "resource_name",
    "fct_undocumented_public_models": "resource_name",
    "fct_undocumented_source_tables": "resource_name",
    "fct_undocumented_sources": "source_name",
    "fct_unused_sources": "parent",
}

# 1.x columns of the fct_ models (to tell "wrong column" from "not a column of this model")
V1_COLUMNS = {
    "fct_chained_views_dependencies": {"child", "distance", "parent", "path"},
    "fct_direct_join_to_source": {"child", "child_resource_type", "distance", "parent", "parent_resource_type"},
    "fct_duplicate_sources": {"source_db_location", "source_names"},
    "fct_exposure_parents_materializations": {"exposure_name", "parent_model_materialization", "parent_resource_name", "parent_resource_type"},
    "fct_exposures_dependent_on_private_models": {"exposure_name", "parent_resource_name", "parent_access", "parent_resource_type"},
    "fct_marts_or_intermediate_dependent_on_source": {"parent", "parent_resource_type", "child", "child_model_type"},
    "fct_missing_primary_key_tests": {"resource_name", "resource_type", "model_type", "is_primary_key_tested", "number_of_tests_on_model", "number_of_constraints_on_model"},
    "fct_model_directories": {"resource_name", "resource_type", "model_type", "current_file_path", "change_file_path_to"},
    "fct_model_fanout": {"parent", "parent_model_type", "leaf_children"},
    "fct_model_naming_conventions": {"resource_name", "model_type", "prefix", "appropriate_prefixes"},
    "fct_multiple_sources_joined": {"child", "source_parents"},
    "fct_public_models_without_contract": {"resource_name", "is_public", "is_contract_enforced"},
    "fct_rejoining_of_upstream_concepts": {"parent", "child", "parent_and_child", "is_loop_independent"},
    "fct_root_models": {"child"},
    "fct_source_directories": {"resource_name", "resource_type", "current_file_path", "change_file_path_to"},
    "fct_source_fanout": {"parent", "model_children"},
    "fct_sources_without_freshness": {"resource_name"},
    "fct_staging_dependent_on_marts_or_intermediate": {"child", "child_model_type", "parent", "parent_model_type"},
    "fct_staging_dependent_on_staging": {"child", "child_model_type", "parent", "parent_model_type"},
    "fct_test_directories": {"test_name", "model_name", "current_test_directory", "change_test_directory_to"},
    "fct_too_many_joins": {"resource_name", "file_path", "join_count"},
    "fct_undocumented_models": {"resource_name", "model_type"},
    "fct_undocumented_public_models": {"resource_name", "access", "is_described", "total_defined_columns", "total_described_columns"},
    "fct_undocumented_source_tables": {"resource_name"},
    "fct_undocumented_sources": {"source_name"},
    "fct_unused_sources": {"parent"},
}

NOT_APPLICABLE = {
    "fct_hard_coded_references": "the rule no longer exists in 2.x (see 'Hard-coded references' in the migration guide)",
    "fct_documentation_coverage": "coverage rules are project-wide metrics and never supported exceptions; use the documentation_coverage_target var",
    "fct_test_coverage": "coverage rules are project-wide metrics and never supported exceptions; use the test_coverage_target var",
}

COLUMN_HINTS = {
    ("fct_direct_join_to_source", "parent"): "the 2.x violation points at the child model: list the child (`child`) instead",
    ("fct_staging_dependent_on_staging", "parent"): "the 2.x violation points at the child model: list the child (`child`) instead",
    ("fct_staging_dependent_on_marts_or_intermediate", "parent"): "the 2.x violation points at the child model: list the child (`child`) instead",
    ("fct_chained_views_dependencies", "parent"): "the 2.x violation points at the child model: list the child (`child`) instead",
    ("fct_rejoining_of_upstream_concepts", "parent"): "the 2.x violation points at `parent_and_child` (the in-between model): list that one instead",
    ("fct_rejoining_of_upstream_concepts", "child"): "the 2.x violation points at `parent_and_child` (the in-between model): list that one instead",
    ("fct_model_fanout", "leaf_children"): "list the parent (`parent`) instead",
    ("fct_multiple_sources_joined", "source_parents"): "list the model (`child`) instead",
    ("fct_source_fanout", "model_children"): "list the source (`parent`) instead",
}

CHECK_HINT_NO_RESOURCE = {
    "fct_duplicate_sources": "each source of a group is its own row in 2.x: list the sources individually (`source_name.table`)",
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
    """Returns (translated {fct: [(pattern, comment, note)]}, review [(row_no, line, reason)], na [(row_no, line, reason)])."""
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
        if fct not in RESOURCE_COLUMN:
            review.append((number, original, f"'{fct}' is not a rule of dbt_project_evaluator 2.x (typo, or a rule that was removed)"))
            continue
        if not pattern:
            review.append((number, original, "empty id_to_exclude"))
            continue
        if any(token in pattern for token in JINJA_OPENERS) or "\n" in pattern:
            review.append((number, original, "the pattern contains Jinja delimiters or a line break and cannot be written safely in a macro"))
            continue
        resource_column = RESOURCE_COLUMN[fct]
        if resource_column is None:
            review.append((number, original, CHECK_HINT_NO_RESOURCE[fct]))
            continue
        if column != resource_column:
            if column in V1_COLUMNS[fct]:
                reason = COLUMN_HINTS.get((fct, column)) or (
                    f"2.x only matches the resource the violation points at (`{resource_column}` in 1.x); "
                    f"`{column}` has no equivalent"
                )
            else:
                reason = f"'{column}' is not a column of {fct} in 1.x"
            review.append((number, original, reason))
            continue
        note = ""
        if fct == "fct_undocumented_sources":
            # 2.x reports one row per source, carrying the unique_id of one of its tables: match any table
            pattern, note = pattern + ".%", "was a source name; matches any table of the source"
        translated.setdefault(fct, []).append((pattern, comment, note))
    return translated, review, na


def render_mapping(translated, review, na, indent, source_name):
    """YAML lines (a mapping + comments) at the given indentation."""
    pad = " " * indent
    lines = []
    for fct in sorted(translated):
        lines.append(f"{pad}{fct}:")
        seen = set()
        for pattern, comment, note in translated[fct]:
            if pattern in seen:
                continue
            seen.add(pattern)
            trailing = " ".join(part for part in (comment, f"[{note}]" if note else "") if part)
            lines.append(f"{pad}  - {yaml_quote(pattern)}" + (f"   # {trailing}" if trailing else ""))
    if review:
        lines += ["", f"{pad}# NEEDS REVIEW: 1.x exceptions that could not be translated automatically.",
                  f"{pad}# 2.x matches a pattern against the name or unique_id of the resource a violation points at."]
        for number, original, reason in review:
            lines.append(f"{pad}# {source_name}:{number}: {original}")
            lines.append(f"{pad}#     -> {reason}")
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
            "{# Generated by scripts/migrate_to_v2.py from " + source_name + ". Violations of dbt_project_evaluator checks that this project accepts. #}",
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
        ["# Generated by scripts/migrate_to_v2.py from " + source_name, "vars:", "  dbt_project_evaluator_exceptions:", *(body or ["    {}"]), ""]
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
] + sorted(set(RESOURCE_COLUMN) | {"fct_hard_coded_references", "fct_documentation_coverage", "fct_test_coverage"})
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
            elif name == "exclude_packages":
                if any(item.lower() == "all" for item in scalar_items(lines, i)):
                    findings.append(Finding(f"{rel}:{i + 1}", "`exclude_packages` contains 'all', which is not supported in 2.x",
                                            "List the packages to exclude by name"))
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
        (re.compile(r"package:dbt_project_evaluator"), "selects or excludes the package's models", "Use `dbt check` (and `--select state:modified --state <dir>`); drop the package from selectors/excludes"),
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
                    findings.append(Finding(f"{path.relative_to(project_dir)}:{i}", what, fix))

    ref_regex = re.compile(r"""(?:ref)\(\s*['"](?:dbt_project_evaluator['"]\s*,\s*['"])?(%s)['"]""" % "|".join(map(re.escape, V1_MODELS)))
    for path in iter_files(project_dir, lambda p: p.suffix == ".sql"):
        for i, line in enumerate(read_text(path).splitlines(), start=1):
            m = ref_regex.search(line)
            if m:
                findings.append(Finding(f"{path.relative_to(project_dir)}:{i}", f"refs `{m.group(1)}`, a 1.x model that no longer exists",
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
                source_name = str(csv_path.resolve().relative_to(project_dir))
            except ValueError:
                source_name = csv_path.name
            render = render_macro if args.format == "macro" else render_var
            text = render(translated, review, na, source_name)
            output = args.output or (str(project_dir / "macros" / "dbt_project_evaluator_exceptions.sql") if args.format == "macro" else "-")
            count = sum(len({p for p, _, _ in v}) for v in translated.values())
            if output == "-":
                sys.stdout.write(text + "\n")
                log = sys.stderr
            else:
                target = Path(output)
                if target.exists() and not args.force:
                    print(f"{target} already exists (use --force to overwrite)", file=sys.stderr)
                    return 2
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(text, encoding="utf-8")
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
