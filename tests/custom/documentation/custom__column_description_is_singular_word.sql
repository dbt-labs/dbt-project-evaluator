{{ config(severity=env_var("DBT_PROJECT_EVALUATOR_SEVERITY", "warn")) }}
/*
Every column description should be meaningful.
Flag all columns that are single word
*/
select 
    _dbt_source_relation,
    node_unique_id,
    name,
    description,
    data_type,
    quote
from {{ ref("stg_columns") }}
left outer join
    {{ ref("stg_nodes") }} on stg_columns.node_unique_id = stg_nodes.unique_id
where
    -- Manually list centrally managed packages.  Ideally this would just
    -- check for
    -- current package name.
    stg_nodes.package_name
    not in ('dbt_project_evaluator', 'dig_dbt_sources', 'dig_dbt_utils')
    -- counts how many spaces are present - after trimming to avoid trailing spaces
    and array_length(split(trim(stg_columns.description), ' ')) < 2 and description != ''
