-- all models with inappropriate (or lack of) pre-fix
-- ensure dbt project has consistent naming conventions

with all_graph_resources as (
    select * from {{ ref('int_all_graph_resources') }}
),

naming_convention_prefixes as (
    select * from {{ ref('stg_naming_convention_prefixes') }}
), 

appropriate_prefixes as (
    select 
        model_type, 
        {{ dbt_utils.listagg('prefix_value', "', '", 'order by prefix_value') }} as appropriate_prefixes
    from naming_convention_prefixes
    group by model_type
), 

models as (
    select
        all_graph_resources.resource_name,
        all_graph_resources.prefix,
        all_graph_resources.model_type,
        naming_convention_prefixes.prefix_value
    from all_graph_resources 
    left join naming_convention_prefixes
        on all_graph_resources.model_type = naming_convention_prefixes.model_type
        and all_graph_resources.prefix = naming_convention_prefixes.prefix_value
    where resource_type = 'model'
),

inappropriate_model_names as (
    select 
        models.resource_name,
        models.prefix,
        models.model_type,
        appropriate_prefixes.appropriate_prefixes
    from models
    left join appropriate_prefixes
        on models.model_type = appropriate_prefixes.model_type
    where models.prefix_value is null

)

select * from inappropriate_model_names

{{ filter_exceptions(this) }}