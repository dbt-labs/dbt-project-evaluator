{% set cols = [
  ('created_at', 'timestamp'),
  ('database', 'varchar'),
  ('description', 'variant'),
  ('external', 'boolean'),
  ('freshness', 'variant'),
  ('loaded_at_field', 'varchar'),
  ('loader', 'varchar'),
  ('meta', 'varchar'),
  ('name', 'varchar'),
  ('relation_name', 'varchar'),
  ('resource_type', 'varchar'),
  ('schema', 'varchar'),
  ('source_description', 'varchar'),
  ('source_meta', 'variant'),
  ('source_name', 'varchar'),
  ('tags', 'variant'),
  ('unique_id', 'varchar'),
] %}

{% set config_cols = [
  ('enabled','boolean')
] %}

with all_nodes as (
    select * from {{ ref('stg_project_graph__raw') }}
),

flatten as (
    select 
        nodes.key as node_name,
        nodes.value as node_data
    from all_nodes,
    lateral flatten(manifest:sources) as nodes

),

final as (

    select 
        node_name
        {% for col in cols %}
        , node_data:{{ col[0] }}::{{ col[1] }} as {{ col[0] }}          
        {% endfor %}
        {% for col in config_cols %}
        , node_data:config:"{{ col[0] }}"::{{ col[1] }} as config_{{ col[0] | replace('-','_') }}          
        {% endfor %}
    from flatten
)

select * from final