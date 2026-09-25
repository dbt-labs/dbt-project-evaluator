#!/bin/bash
# Runs the package's native checks against this fixture and compares the number of
# violations per check with expected_violations.csv.
# Usage: ./run_checks.sh   (needs dbt v2 on PATH)
set -uo pipefail
cd "$(dirname "$0")"

dbt deps --profiles-dir . || exit 1
output=$(dbt check --profiles-dir . 2>&1)
echo "$output"

actual=$(echo "$output" \
    | sed -n "s/.*check '\([a-z_]*\)' \(found\|failed\) with \([0-9]*\) violation.*/\1,\3/p" \
    | sort -u)
expected=$(tail -n +2 expected_violations.csv | sort)

if [ "$actual" != "$expected" ]; then
    echo "Violation counts differ from expected_violations.csv (< expected, > actual):"
    diff <(echo "$expected") <(echo "$actual")
    exit 1
fi

# --select scopes rows by unique_id; project-wide checks ignore it
selected=$(dbt check fct_undocumented_models fct_test_coverage fct_model_fanout --select stg_orders --profiles-dir . 2>&1)
echo "$selected" | grep -q "check 'fct_undocumented_models' found with 1 violation" || { echo "--select did not scope fct_undocumented_models"; exit 1; }
echo "$selected" | grep -q "check 'fct_test_coverage' found with 1 violation" || { echo "--select should not scope fct_test_coverage"; exit 1; }
echo "$selected" | grep -q "fct_model_fanout" && echo "$selected" | grep -q "check 'fct_model_fanout' found" && { echo "--select did not scope fct_model_fanout"; exit 1; }

echo "All native checks returned the expected violations."
