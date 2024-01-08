-- cases where a marts/intermediate model directly references a raw source
with direct_relationships as (
    select
        *
    from {{ ref('int_all_dag_relationships') }}
    where distance = 1
    and not parent_is_excluded
    and not child_is_excluded
),
final as (
    select
        parent,
        parent_resource_type,
        child,
        child_model_type
    from direct_relationships
    where parent_resource_type = 'source'
    and child_model_type in ('marts', 'intermediate')
)
select * from final

{{ filter_exceptions(model.name) }}
