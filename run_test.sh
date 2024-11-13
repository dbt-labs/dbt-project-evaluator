#!/bin/bash
VENV="venv/bin/activate"

if [[ ! -f $VENV ]]
then
    python3 -m venv venv
    . $VENV

    pip install --upgrade pip setuptools "dbt-$1" dbt-core

fi

. $VENV

cd integration_tests
dbt deps --target $1 || exit 1
dbt build -x --target $1 --full-refresh || exit 1

# test with the second project
cd ../integration_tests_2
dbt deps --target $1 || exit 1
dbt seed --full-refresh --target $1 || exit 1
dbt run -x --target $1 --full-refresh || exit 1
