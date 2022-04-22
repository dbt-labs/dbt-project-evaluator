-- all models with inappropriate (or lack of) pre-fix
-- ensure dbt project has consistent naming conventions

-- TO DO: how to handle base models?

with all_graph_resources as (
    select * from {{ ref('stg_all_graph_resources') }}
),

models as (
    select
        resource_name,
        {{ dbt_utils.split_part('resource_name', "'_'", 1) }}||'_' as prefix,
        model_type,
        case 
            when model_type = 'staging' then '{{ var("staging_prefixes") | join(", ") }}'
            when model_type = 'intermediate' then '{{ var("intermediate_prefixes") | join(", ") }}'
            when model_type = 'marts' then '{{ var("marts_prefixes") | join(", ") }}'
            when model_type = 'other' then '{{ var("other_prefixes") | join(", ") }}'
            else null -- TO DO: how do we handle additional model types? 
        end as appropriate_prefixes
    from all_graph_resources 
    where resource_type = 'model'
),

inappropriate_model_names as (
    select 
        resource_name,
        prefix,
        model_type,
        appropriate_prefixes
    from models
    where coalesce( {{ dbt_utils.position('prefix', 'appropriate_prefixes') }}, 0) = 0

)

select * from inappropriate_model_names