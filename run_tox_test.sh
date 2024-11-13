#!/bin/bash

# test with the first project
cd integration_tests
dbt deps --target $1 || exit 1
dbt build -x --target $1 --full-refresh || exit 1

# test with the second project
cd ../integration_tests_2
dbt deps --target $1 || exit 1
dbt seed --full-refresh --target $1 || exit 1
dbt run -x --target $1 --full-refresh || exit 1
