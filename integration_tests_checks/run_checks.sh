#!/bin/bash
# Runs the package's native checks against every fixture project in this folder and compares the
# number of violations per check with the project's expected_violations.csv.
# Usage: ./run_checks.sh   (needs dbt v2 on PATH)
set -uo pipefail
cd "$(dirname "$0")"

status=0

# every check must be known to the exceptions validation (macros/checks/evaluator_exceptions.sql)
declared=$(sed -n "/macro evaluator_check_names/,/endmacro/p" ../macros/checks/evaluator_exceptions.sql | grep -o "'fct_[a-z_]*'" | tr -d "'" | sort)
shipped=$(ls ../checks/*/fct_*.sql | xargs -n1 basename | sed 's/\.sql$//' | grep -v -e '^fct_documentation_coverage$' -e '^fct_test_coverage$' | sort)
if [ "$declared" != "$shipped" ]; then
    echo "evaluator_check_names() is out of sync with checks/ (< declared, > shipped):"
    diff <(echo "$declared") <(echo "$shipped")
    status=1
fi

for project in violations parity_1x parity_1x_no_exposures parity_1x_semantic_layer; do
    echo "=== $project"
    pushd "$project" > /dev/null || exit 1

    dbt deps --profiles-dir . || exit 1
    output=$(dbt check --profiles-dir . 2>&1)
    echo "$output"

    actual=$(echo "$output" \
        | sed -En "s/.*check '([a-z_]+)' (found|failed) with ([0-9]+) violation.*/\1,\3/p" \
        | sort -u)
    expected=$(tail -n +2 expected_violations.csv | sort)

    if [ "$actual" != "$expected" ]; then
        echo "$project: violation counts differ from expected_violations.csv (< expected, > actual):"
        diff <(echo "$expected") <(echo "$actual")
        status=1
    fi

    if [ "$project" = "violations" ]; then
        # --select scopes rows by unique_id; project-wide checks ignore it
        selected=$(dbt check fct_undocumented_models fct_test_coverage fct_model_fanout --select stg_orders --profiles-dir . 2>&1)
        echo "$selected" | grep -q "check 'fct_undocumented_models' found with 1 violation" || { echo "--select did not scope fct_undocumented_models"; status=1; }
        echo "$selected" | grep -q "check 'fct_test_coverage' found with 1 violation" || { echo "--select should not scope fct_test_coverage"; status=1; }
        echo "$selected" | grep -q "check 'fct_model_fanout' found" && { echo "--select did not scope fct_model_fanout"; status=1; }
    fi

    if [ "$project" = "parity_1x" ]; then
        # exceptions for a name that is not a check are rejected
        rejected=$(dbt check --vars '{dbt_project_evaluator_exceptions: {fct_not_a_check: [x]}}' --profiles-dir . 2>&1)
        echo "$rejected" | grep -q "'fct_not_a_check' is not a check of dbt_project_evaluator" || { echo "an unknown check name in the exceptions was not rejected"; status=1; }
    fi

    popd > /dev/null
done

if [ $status -eq 0 ]; then
    echo "All native checks returned the expected violations."
fi
exit $status
