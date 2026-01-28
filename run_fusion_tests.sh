#!/bin/bash

# Run integration tests using dbt Fusion
# Usage: ./run_fusion_tests.sh <target>
# Note: --static-analysis=off is required for Fusion compatibility
# Note: deactivate_for_fusion=true disables tests that are not compatible with Fusion

FUSION_VARS='{"deactivate_for_fusion": true}'

echo "Running Fusion tests for the first project"
cd integration_tests
dbt deps --target $1 || exit 1
dbt build -x --target $1 --full-refresh --static-analysis=off --vars "$FUSION_VARS" || exit 1

echo "Running Fusion tests for the second project"
cd ../integration_tests_2
dbt deps --target $1 || exit 1
dbt seed --full-refresh --target $1 --static-analysis=off --vars "$FUSION_VARS" || exit 1
dbt run -x --target $1 --full-refresh --static-analysis=off --vars "$FUSION_VARS" || exit 1
