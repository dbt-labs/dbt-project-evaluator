
{{ config(severity=env_var("DBT_PROJECT_EVALUATOR_SEVERITY", "warn")) }}
/*
Documentation needs to be wherever people access the data.
Make sure that all BQ assets have descriptions stored in BigQuery

Make your life easy and just put once at the top of your dbt_project.yml file

 ################## Example  ##################

  name: 'dig_dbt_sources'
  version: '1.0.0'
  config-version: 2
  models:
    +persist_docs:
      relation: true
      columns: true

 ##############################################

https://docs.getdbt.com/reference/resource-configs/persist_docs
*/
with
    extract_json as (
        select
            -- Work to do:  Fix the boolean replace function upstream in the forked
            -- project_evaluator package
            coalesce(
                json_value(replace(persist_docs, ": True", ": 'True'"), '$.columns'), ''
            ) as persist_docs__relation,
            coalesce(
                json_value(replace(persist_docs, ": True", ": 'True'"), '$.columns'), ''
            ) as persist_docs__columns,
            *
        from {{ ref("stg_nodes") }}
    )
select
    -- Work to do:  Fix the boolean replace function upstream in the forked
    -- project_evaluator package
    coalesce(
        json_value(replace(persist_docs, ": True", ": 'True'"), '$.columns'), ''
    ) as persist_docs__relation,
    coalesce(
        json_value(replace(persist_docs, ": True", ": 'True'"), '$.columns'), ''
    ) as persist_docs__columns,
    unique_id,
    name,
    resource_type,
    materialized,
    on_schema_change,
    incremental_strategy,
    partition_by,
    full_refresh
from extract_json
where
    resource_type in ('model', 'snapshot')
    and (persist_docs__relation != 'True' or persist_docs__columns != 'True')
    -- Manually list centrally managed packages.  Ideally this would just check for
    -- current package name.
    and package_name
    not in ('dbt_project_evaluator', 'dig_dbt_sources', 'dig_dbt_utils')
    
