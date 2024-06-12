{{ config(severity=env_var("DBT_PROJECT_EVALUATOR_SEVERITY", "warn")) }}
/*
Do any columns share the same name but have different descriptions?
Descriptions should be defined only once and used consistently.
*/
with
    count_unique_descriptions as (

        select
            stg_columns.name,
            count(distinct trim(stg_columns.description)) as num_unique_descriptions -- trim to remove whitespace
        from {{ ref("stg_columns") }}
        left outer join
            {{ ref("stg_nodes") }} on stg_columns.node_unique_id = stg_nodes.unique_id
        where
            -- Manually list centrally managed packages.  Ideally this would just
            -- check for
            -- current package name.
            stg_nodes.package_name
            not in ('dbt_project_evaluator', 'dig_dbt_sources', 'dig_dbt_utils')

        group by all

    )
select *
from count_unique_descriptions
where num_unique_descriptions > 1
