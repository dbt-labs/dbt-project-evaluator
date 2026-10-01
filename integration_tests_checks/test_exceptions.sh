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

# 4. --select still applies to what is left: int_chain_1 is excepted, stg_orders is not
pushd violations > /dev/null || exit 1
output=$(dbt check fct_undocumented_models --select stg_orders int_chain_1 --profiles-dir . 2>&1)
echo "$output" | grep -q "check 'fct_undocumented_models' found with 1 violation" \
    || fail "violations: --select combined with an exception should report only stg_orders"
popd > /dev/null

[ $status -eq 0 ] && echo "Exception tests passed."
exit $status
