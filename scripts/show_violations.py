#!/usr/bin/env python3
"""Show every violation of a check: `dbt check` prints only the first 5 rows of each check.

    python dbt_packages/dbt_project_evaluator/scripts/show_violations.py fct_missing_primary_key_tests
    python dbt_packages/dbt_project_evaluator/scripts/show_violations.py fct_model_fanout --format csv
    python dbt_packages/dbt_project_evaluator/scripts/show_violations.py fct_model_fanout --where "original_file_path like 'models/staging/%'"
    python dbt_packages/dbt_project_evaluator/scripts/show_violations.py fct_model_fanout --no-run

Run it from the root of the dbt project after `dbt check`. Options it does not know (`--vars`,
`--target`, `--profiles-dir`, ...) are passed to `dbt check`, so the check sees the same variables
and exceptions as in your own run.

`dbt check` applies `--select` (and `state:modified`) to the rows a check returns, not to its query,
so the script shows the violations of the whole project. To keep some of them, use `--where` with
a condition on the columns of the check, e.g. `--where "unique_id like '%staging%'"`.

How it works: dbt logs every statement of a check run in `query_log.sql`: the views over the
metadata of the project, then the query of the check, already rendered with the variables and the
exceptions of the project. The script runs `dbt check <check>`, keeps those statements and replays
them in DuckDB, without a limit on the number of rows. The statements are also written to
`target/check_violations/<check>.sql` (change it with `--sql-file`), so that you can open the file
in DuckDB yourself: `duckdb -box < target/check_violations/<check>.sql`, or `--no-run` to write the
file without running it.

DuckDB is needed to run the statements: the `duckdb` command line, or the `duckdb` Python package.
Python 3 standard library otherwise. Use `python3` instead of `python` if `python` is not found
(macOS, Linux), `py` on Windows, or `uv run --with duckdb dbt_packages/dbt_project_evaluator/scripts/show_violations.py`
anywhere.
"""
import argparse
import csv
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# dbt's own views over the project metadata use the `x -> ...` lambda syntax, which DuckDB warns about
# (on stdout, which would end up in the csv and json output)
SETUP = "SET lambda_syntax='ENABLE_SINGLE_ARROW';"
SELECTION_OPTIONS = ("-s", "--select", "--exclude", "--selector")
CLI_FORMATS = {"table": "-box", "csv": "-csv", "json": "-json", "markdown": "-markdown"}


def read_statements(query_log):
    """DuckDB statements of a query log: a metadata header (`-- created_at:` ... `-- desc:`), then the SQL."""
    statements = []
    for block in re.split(r"(?m)^(?=-- created_at: )", query_log.read_text(encoding="utf-8")):
        dialect = re.search(r"(?m)^-- dialect: (\w+)", block)
        parts = re.split(r"(?m)^-- desc:.*\n", block, maxsplit=1)
        if not dialect or dialect.group(1) != "duckdb" or len(parts) != 2:
            continue
        sql = parts[1].strip()
        if sql:
            statements.append(sql if sql.endswith(";") else sql + ";")
    return statements


def is_query(statement):
    """The setup statements create the views; the query of the check is a `with` or a `select`."""
    code = re.sub(r"(?m)^\s*--.*$", "", statement).strip()
    return code.split(None, 1)[0].lower() in ("with", "select")


def print_table(columns, rows):
    cells = [[("" if v is None else str(v)) for v in row] for row in rows]
    widths = [max([len(c)] + [len(r[i]) for r in cells]) for i, c in enumerate(columns)]
    line = "  ".join(c.ljust(w) for c, w in zip(columns, widths))
    print(line)
    print("  ".join("-" * w for w in widths))
    for r in cells:
        print("  ".join(v.ljust(w) for v, w in zip(r, widths)))


def run_with_python(script, fmt):
    import duckdb  # imported here so that the script works without it when only the CLI is used

    connection = duckdb.connect()
    try:
        connection.execute(SETUP)
    except duckdb.Error:  # a DuckDB that does not know the setting does not need it
        pass
    connection.execute(script.replace(SETUP, "", 1))
    columns = [d[0] for d in connection.description]
    rows = connection.fetchall()
    if fmt == "csv":
        writer = csv.writer(sys.stdout, lineterminator="\n")
        writer.writerow(columns)
        writer.writerows(rows)
    elif fmt == "json":
        print(json.dumps([dict(zip(columns, r)) for r in rows], default=str, indent=2))
    else:
        print_table(columns, rows)
    print(f"{len(rows)} row(s)", file=sys.stderr)
    return 0


def run(script, fmt):
    cli = shutil.which("duckdb")
    if cli:
        flag = CLI_FORMATS.get(fmt, "-box")
        return subprocess.run([cli, flag], input=script, text=True, encoding="utf-8").returncode
    try:
        return run_with_python(script, fmt)
    except ImportError:
        return None


def main():
    parser = argparse.ArgumentParser(
        description="Show every violation of a dbt_project_evaluator check. Other options are passed to `dbt check`.",
        epilog="Example: show_violations.py fct_model_fanout --where \"unique_id like '%staging%'\" --vars '{models_fanout_threshold: 2}'",
    )
    parser.add_argument("check", help="name of the check, as printed by `dbt check` (e.g. fct_model_fanout)")
    parser.add_argument("--project-dir", default=".", help="root of the dbt project (default: .)")
    parser.add_argument("--where", help="SQL condition on the columns of the check, to keep only some of the violations")
    parser.add_argument("--format", choices=list(CLI_FORMATS), default="table", help="output format (default: table)")
    parser.add_argument("--sql-file", help="where to write the statements (default: <project-dir>/target/check_violations/<check>.sql)")
    parser.add_argument("--no-run", action="store_true", help="write the SQL file but do not run it")
    args, dbt_args = parser.parse_known_args()
    if any(a.split("=")[0] in SELECTION_OPTIONS for a in dbt_args):
        print("note: dbt applies a selection to the rows of a check, not to its query: the script shows the "
              "violations of the whole project. Use --where to keep some of them.", file=sys.stderr)

    dbt = shutil.which("dbt")
    if not dbt:
        sys.exit("dbt was not found on the PATH (dbt v2 is needed)")

    project_dir = Path(args.project_dir).resolve()
    log_dir = Path(tempfile.mkdtemp(prefix="show_violations_"))
    try:
        # the project's own logs/ folder is left alone: the log of this run only has this check
        command = [dbt, "check", args.check, "--project-dir", str(project_dir), "--log-path", str(log_dir)] + dbt_args
        result = subprocess.run(command, stdin=subprocess.DEVNULL, capture_output=True, text=True, encoding="utf-8", errors="replace")
        query_log = log_dir / "query_log.sql"
        statements = read_statements(query_log) if query_log.exists() else []
        if not statements or not is_query(statements[-1]):
            sys.stderr.write(result.stdout[-3000:] + result.stderr[-3000:])
            sys.exit(f"`dbt check {args.check}` did not run the check (is the name right? see the output above)")
    finally:
        shutil.rmtree(log_dir, ignore_errors=True)

    if args.where:
        statements[-1] = f"select * from (\n{statements[-1].rstrip().rstrip(';')}\n) as violations where {args.where};"

    sql_file = Path(args.sql_file) if args.sql_file else project_dir / "target" / "check_violations" / f"{args.check}.sql"
    sql_file.parent.mkdir(parents=True, exist_ok=True)
    script = "\n\n".join([SETUP] + statements) + "\n"
    sql_file.write_text(script, encoding="utf-8")

    if args.no_run:
        print(f"Statements written to {sql_file}\nRun them with: duckdb -box < {sql_file}")
        return 0
    status = run(script, args.format)
    if status is None:
        print(
            f"DuckDB is needed to run the check: install the `duckdb` command line or `pip install duckdb`.\n"
            f"The statements are in {sql_file}\nRun them with: duckdb -box < {sql_file}",
            file=sys.stderr,
        )
        return 1
    return status


if __name__ == "__main__":
    sys.exit(main())
