{% macro get_unpack_sql(resource_type) %}

    {% if execute %}  
        {% set resources = graph[resource_type].values() %}    
        {% if resource_type == 'nodes' %}
            {{ get_node_unpack_sql(resources) }}
        {% elif resource_type == 'sources' %}
            {{ get_source_unpack_sql(resources) }}
        {% elif resource_type == 'exposures' %}
            {{ get_exposure_unpack_sql(resources) }}
        {% elif resource_type == 'metrics' %}
            {{ get_metric_unpack_sql(resources) }}
        {% endif %}

    {% endif %}
    
{% endmacro %}


{% macro get_node_unpack_sql(nodes_list) %}

    {% for node in nodes_list %}
        {% if not loop.first %}
          union all 
        {% endif %}

        select 
            '{{ node.unique_id }}' as unique_id,
            '{{ node.name }}' as node_name,
            '{{ node.resource_type }}' as resource_type,
            parse_json('{{ node.depends_on | tojson }}') as depends_on,
            '{{ node.config.enabled }}'::boolean as is_enabled,
            '{{ node.config.materialized }}' as materialized,
            '{{ node.config.on_schema_change}}' as on_schema_change,
            '{{ node.database }}' as database,
            '{{ node.schema }}' as schema,
            '{{ node.package_name }}' as package_name,
            '{{ node.alias }}' as alias,
            array_agg('{{ node.tags | join(', ') }}') as tags,
            parse_json('{{ node.refs | tojson }}') as refs,
            parse_json('{{ node.sources | tojson }}') as sources,
            '{{ node.description }}' as description,
            parse_json('{{ node.columns | tojson }}') as columns,
            parse_json('{{ node.meta | tojson }}') as meta

    {% endfor %}
  
{% endmacro %}

{% macro get_source_unpack_sql(nodes_list) %}

    {% for node in nodes_list %}
        {% if not loop.first %}
          union all 
        {% endif %}

        select 
            '{{ node.unique_id }}' as unique_id,
            '{{ node.name }}' as node_name,
            '{{ node.alias }}' as alias,
            '{{ node.resource_type }}' as resource_type,
            '{{ node.source_name }}' as source_name,
            '{{ node.source_description }}' as source_description,
            '{{ node.description }}' as description,
            '{{ node.config.enabled }}'::boolean as is_enabled,
            '{{ node.loaded_at_field}}' as loaded_at_field,
            '{{ node.database }}' as database,
            '{{ node.schema }}' as schema,
            '{{ node.package_name }}' as package_name,
            '{{ node.loader }}' as loader,
            '{{ node.identifier }}' as identifier,
            parse_json('{{ node.quoting | tojson }}') as quoting,
            array_agg('{{ node.tags | join(', ') }}') as tags,
            parse_json('{{ node.freshness | tojson }}') as freshness,
            parse_json('{{ node.columns | tojson }}') as columns,
            parse_json('{{ node.source_meta | tojson }}') as source_meta,
            parse_json('{{ node.meta | tojson }}') as meta

    {% endfor %}
  
{% endmacro %}


{% macro get_exposure_unpack_sql(nodes_list) %}

    {% for node in nodes_list %}
        {% if not loop.first %}
          union all 
        {% endif %}

        select 
            '{{ node.unique_id }}' as unique_id,
            '{{ node.name }}' as node_name,
            '{{ node.resource_type }}' as resource_type,
            '{{ node.description }}' as description,
            '{{ node.type }}' as exposure_type,
            '{{ node.maturity}}' as maturity,
            '{{ node.package_name }}' as package_name,
            '{{ node.url }}' as url,
            parse_json('{{ node.depends_on | tojson }}') as depends_on,
            parse_json('{{ node.refs | tojson }}') as refs,
            parse_json('{{ node.sources | tojson }}') as sources,
            parse_json('{{ node.owner | tojson }}') as owner,
            array_agg('{{ node.tags | join(', ') }}') as tags,
            parse_json('{{ node.meta | tojson }}') as meta

    {% endfor %}
  
{% endmacro %}

{% macro get_metric_unpack_sql(nodes_list) %}

    {% for node in nodes_list %}
        {% if not loop.first %}
          union all 
        {% endif %}

        select 
            '{{ node.unique_id }}' as unique_id,
            '{{ node.name }}' as node_name,
            '{{ node.resource_type }}' as resource_type,
            '{{ node.description }}' as description,
            '{{ node.type }}' as metric_type,
            '{{ node.model.identifier }}' as model,
            '{{ node.label }}' as label,
            '{{ node.sql }}' as sql,
            '{{ node.timestamp }}' as timestamp,
            '{{ node.package_name }}' as package_name,
            parse_json('{{ node.depends_on | tojson }}') as depends_on,
            parse_json('{{ node.filters | tojson }}') as filters,
            parse_json('{{ node.refs | tojson }}') as refs,
            parse_json('{{ node.sources | tojson }}') as sources,
            array_agg('{{ node.tags | join(', ') }}') as tags,
            array_agg('{{ node.time_grains | join(', ') }}') as time_grains,
            array_agg('{{ node.dimensions | join(', ') }}') as dimensions,
            parse_json('{{ node.meta | tojson }}') as meta

    {% endfor %}
  
{% endmacro %}


