-- this model finds cases where a model has 0 direct parents, likely due to a lack of source or ref function

{% if execute %}
{% set metric_flow_time_spine_names = graph.nodes.values()
     | selectattr("resource_type", "equalto", "model") 
     | rejectattr("time_spine", "none") 
     | map(attribute = "name") 
     | join("', '")
%}
{% endif %}

with model_relationships as (
    select  
        *
    from {{ ref('int_all_dag_relationships') }}
    where child_resource_type = 'model'
    -- only filter out excluded children nodes
        -- filtering parents could result in incorrectly flagging nodes that depend on excluded nodes
    and not child_is_excluded
    -- exclude required time spine
    {% if metric_flow_time_spine_names %}
    and child not in ('{{ metric_flow_time_spine_names }}')
    {% endif %}
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