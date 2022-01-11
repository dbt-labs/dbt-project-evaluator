{% set cols = [
  ('alias', 'varchar'),
  ('config', 'varchar'),
  ('created_at', 'timestamp'),
  ('database', 'varchar'),
  ('depends_on', 'variant'),
  ('description', 'varchar'),
  ('docs', 'variant'),
  ('meta', 'varchar'),
  ('name', 'varchar'),
  ('package_name', 'varchar'),
  ('refs', 'variant'),
  ('resource_type', 'varchar'),
  ('schema', 'varchar'),
  ('sources', 'variant'),
  ('tags', 'variant'),
  ('unique_id', 'varchar'),
] %}

{% set config_cols = [
  ('enabled','boolean'),
  ('full_refresh','boolean'),
  ('materialized','varchar'),
  ('meta','variant'),
  ('on_schema_change','varchar'),
  ('post-hook','variant'),
  ('pre-hook','variant'),
] %}

with all_nodes as (
    select * from {{ ref('stg_project_graph__raw') }}
),

flatten as (
    select 
        nodes.key as node_name,
        nodes.value as node_data
    from all_nodes,
    lateral flatten(manifest:nodes) as nodes

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