{{ config(severity=env_var("DBT_PROJECT_EVALUATOR_SEVERITY", "warn")) }}
/*
Every column that is defined in yaml must have a description.

Not 100% complete test - relies on Governance suite of testing rules to be passing.
This table does not contain columns which have not been inputed into yaml.
Will not catch columns which have not been defined in the YAML.

If dbt project evaluator rules enfore Governance suite (dbt mesh style), this will
always work.
*/
select stg_columns.*
from {{ ref("stg_columns") }}
left outer join {{ ref("stg_nodes") }} on stg_columns.node_unique_id = stg_nodes.unique_id
where
    stg_columns.description is null
    -- Manually list centrally managed packages.  Ideally this would just check for
    -- current package name.
    
    and stg_nodes.package_name
    not in ('dbt_project_evaluator', 'dig_dbt_sources', 'dig_dbt_utils')
