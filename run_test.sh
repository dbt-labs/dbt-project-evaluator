#!/bin/bash
VENV="venv/bin/activate"

if [[ ! -f $VENV ]]; then
    python3 -m venv venv
    . $VENV

    pip install --upgrade pip setuptools
    pip install --pre "dbt-$1"
fi

. $VENV

cd integration_tests

if [[ ! -e ~/.dbt/profiles.yml ]]; then
    mkdir -p ~/.dbt
    cp ci/sample.profiles.yml ~/.dbt/profiles.yml
fi

dbt deps --target $1 || exit 1
dbt build -x --target $1 --full-refresh || exit 1

# test without exposures or metrics
rm models/marts/exposures.yml
rm models/marts/metrics.yml
dbt run -x --target $1 --select +int_direct_relationships +int_all_graph_resources || exit 1