-- this model finds cases where a model has 0 direct parents, likely due to a lack of source or ref function

with model_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where child_resource_type = 'model'
    -- only filter out excluded children nodes
        -- filtering parents could result in incorrectly flagging nodes that depend on excluded nodes
    and not child_is_excluded
    -- exclude required time spine
    and child != 'metricflow_time_spine'
),

final as (
    select
        child
    from model_relationships
    group by 1
    having max(distance) = 0
)

select * from final

{{ filter_exceptions() }}