#!/bin/bash
# Behaviour of exceptions that the expected counts in run_checks.sh do not cover.
# Called by run_checks.sh; needs dbt v2 on PATH.
set -uo pipefail
cd "$(dirname "$0")"

status=0
fail() { echo "exceptions: $1"; status=1; }

# every check but the two project-wide coverage metrics, which exceptions do not apply to
names=$(ls ../checks/*/fct_*.sql | xargs -n1 basename | sed 's/\.sql$//' | grep -v -e '^fct_documentation_coverage$' -e '^fct_test_coverage$')
catch_all=$(echo "$names" | awk '{printf "%s\"%s\": [\"%%\"]", (NR>1 ? ", " : ""), $0}')
all_vars="{dbt_project_evaluator_exceptions: {$catch_all}}"
no_coverage_targets="{documentation_coverage_target: 0, test_coverage_target: 0, dbt_project_evaluator_exceptions: {$catch_all}}"

# 1. an exception matching everything silences every check, on every project that reads the var
for project in parity_1x parity_1x_no_exposures parity_1x_semantic_layer; do
    pushd "$project" > /dev/null || exit 1
    dbt deps --profiles-dir . > /dev/null || exit 1
    output=$(dbt check --vars "$all_vars" --profiles-dir . 2>&1)
    reporting=$(echo "$output" | sed -En "s/.*check '([a-z_]+)' (found|failed) with ([0-9]+) violation.*/\1/p" | grep -v -e '^fct_documentation_coverage$' -e '^fct_test_coverage$')
    [ -z "$reporting" ] || fail "$project: still reported with an exception on '%': $(echo $reporting)"
    echo "$output" | grep -Eq "check 'fct_test_coverage' (found|failed)" || fail "$project: the coverage checks should not be affected by exceptions"
    popd > /dev/null
done

# 2. with errors as severity, exceptions are what makes the run pass
pushd parity_1x_no_exposures > /dev/null || exit 1
dbt check --profiles-dir . > /dev/null 2>&1 && fail "parity_1x_no_exposures: violations at severity error should fail"
dbt check --vars "$no_coverage_targets" --profiles-dir . > /dev/null 2>&1 || fail "parity_1x_no_exposures: all violations are excepted, the run should pass"
popd > /dev/null

# 3. a macro replaces the var; a macro can also be rejected for an unknown check name
pushd parity_1x > /dev/null || exit 1
mkdir -p macros
trap 'rm -rf macros' EXIT
cat > macros/override.sql <<'MACRO'
{% macro default__dbt_project_evaluator_exceptions() %}{{ return({}) }}{% endmacro %}
MACRO
output=$(dbt check fct_undocumented_models --profiles-dir . 2>&1)
echo "$output" | grep -q "check 'fct_undocumented_models' found with 14 violation" \
    || fail "parity_1x: the macro should replace the var (14 undocumented models, 13 with the var)"
cat > macros/override.sql <<'MACRO'
{% macro default__dbt_project_evaluator_exceptions() %}{{ return({'fct_not_a_check': ['x']}) }}{% endmacro %}
MACRO
output=$(dbt check --profiles-dir . 2>&1)
echo "$output" | grep -q "'fct_not_a_check' is not a check of dbt_project_evaluator" \
    || fail "parity_1x: an unknown check name returned by the macro was not rejected"
rm -rf macros
popd > /dev/null

# 3b. entries on a column are validated: bad name, unknown column, empty mapping, no pattern
pushd parity_1x > /dev/null || exit 1
for case in \
    '{fct_root_models: [{"bad col": x}]}|is not a valid column name' \
    '{fct_root_models: [{nope: x}]}|nope' \
    '{fct_root_models: [{}]}|is an empty mapping' \
    '{fct_root_models: [{name: null}]}|needs at least one pattern'; do
    vars=${case%%|*}; expected=${case##*|}
    output=$(dbt check fct_root_models --vars "{dbt_project_evaluator_exceptions: $vars}" --profiles-dir . 2>&1)
    status_code=$?
    [ $status_code -ne 0 ] && echo "$output" | grep -q "$expected" || fail "parity_1x: $vars should fail with '$expected'"
done
popd > /dev/null

# 3c. the dispatched SQL hook: conditions in SQL added to the exceptions of the var
pushd parity_1x > /dev/null || exit 1
mkdir -p macros
hook() { printf '{%% macro default__dbt_project_evaluator_exception_sql(check_name) %%}%s{%% endmacro %%}\n' "$1" > macros/hook.sql; }
check_count() { dbt check fct_undocumented_models fct_missing_primary_key_tests --profiles-dir . 2>&1 | sed -En "s/.*check '$1' (found|failed) with ([0-9]+) violation.*/\2/p"; }
[ "$(check_count fct_undocumented_models)" = "13" ] || fail "parity_1x: 13 undocumented models are expected before adding a hook"

hook "{{ return('true') }}"
[ -z "$(check_count fct_undocumented_models)" ] || fail "parity_1x: a hook returning true should accept every violation"
hook "{{ return(['false', 'false']) }}"
[ "$(check_count fct_undocumented_models)" = "13" ] || fail "parity_1x: a hook returning only false conditions should change nothing"
hook "{{ return(['false', 'true']) }}"
[ -z "$(check_count fct_undocumented_models)" ] || fail "parity_1x: any true condition of the list should accept the violation"
hook "   "
[ "$(check_count fct_undocumented_models)" = "13" ] || fail "parity_1x: an empty hook should change nothing"
hook "violation.unique_id in (select cast(null as varchar))"
[ "$(check_count fct_undocumented_models)" = "13" ] || fail "parity_1x: a condition that is NULL must not drop the violations"
hook "{{ 'true' if check_name == 'fct_undocumented_models' else 'false' }}"
[ -z "$(check_count fct_undocumented_models)" ] || fail "parity_1x: the hook should accept the violations of the check it names"
[ "$(check_count fct_missing_primary_key_tests)" = "13" ] || fail "parity_1x: the hook named another check, fct_missing_primary_key_tests should be unchanged"
hook "violation.name like 'stg_%'"
[ "$(check_count fct_undocumented_models)" -lt 13 ] || fail "parity_1x: a condition on a column of the check should accept some violations"

for case in \
    "{{ return({'a': 'b'}) }}|expected a SQL condition or a list" \
    "{{ return([1]) }}|expected a SQL condition (a string)"; do
    hook "${case%%|*}"
    output=$(dbt check fct_root_models --profiles-dir . 2>&1)
    echo "$output" | grep -qF "${case##*|}" || fail "parity_1x: the hook ${case%%|*} should fail with '${case##*|}'"
done
rm -rf macros
popd > /dev/null

# 4. --select still applies to what is left: int_chain_1 is excepted, stg_orders is not
pushd violations > /dev/null || exit 1
output=$(dbt check fct_undocumented_models --select stg_orders int_chain_1 --profiles-dir . 2>&1)
echo "$output" | grep -q "check 'fct_undocumented_models' found with 1 violation" \
    || fail "violations: --select combined with an exception should report only stg_orders"
popd > /dev/null

# 5. exclude_packages: ['all'] keeps only the root project, and the root project is never excluded
pushd parity_1x > /dev/null || exit 1
counts() { sed -En "s/.*check '([a-z_]+)' (found|failed) with ([0-9]+) violation.*/\1,\3/p" | sort -u; }
expected=$(tail -n +2 expected_violations.csv | sort)
[ "$(dbt check --vars '{exclude_packages: [all]}' --profiles-dir . 2>&1 | counts)" = "$expected" ] \
    || fail "parity_1x: exclude_packages ['all'] should give the same violations as excluding exclude_package"
[ "$(dbt check --vars '{exclude_packages: [dbt_project_evaluator_integration_tests, exclude_package]}' --profiles-dir . 2>&1 | counts)" = "$expected" ] \
    || fail "parity_1x: exclude_packages must not exclude the root project"
[ "$(dbt check --vars '{exclude_packages: []}' --profiles-dir . 2>&1 | counts)" != "$expected" ] \
    || fail "parity_1x: the resources of exclude_package should be reported when it is not excluded"
popd > /dev/null

[ $status -eq 0 ] && echo "Exception tests passed."
exit $status
