{%- macro get_metric_values() -%}
    {{ return(adapter.dispatch('get_metric_values', 'dbt_project_evaluator')()) }}
{%- endmacro -%}

{%- macro default__get_metric_values() -%}

    {%- if execute -%}
    {%- set nodes_list = graph.metrics.values() -%}
    {%- set values = [] -%}

    {%- for node in nodes_list -%}

          {% set metric_filters %}
            {%- if node.filters|length -%}
              {%- for filt in node.filters %}
                '{{ filt.field }}'||'{{ filt.operator }}'||'''{{ dbt.escape_single_quotes(filt.value) }}'''
                {% if not loop.last %}|| ' - ' ||{% endif %}
              {% endfor -%}
            {%- else -%}
                ''
            {% endif -%}
          {% endset %}

          {%- set values_line = 
            [
            wrap_string_with_quotes(node.unique_id),
            wrap_string_with_quotes(node.name),
            wrap_string_with_quotes(node.resource_type),
            wrap_string_with_quotes(node.original_file_path | replace("\\","\\\\")),
            "cast(" ~ dbt_project_evaluator.is_not_empty_string(node.description) | trim ~ " as boolean)",
            wrap_string_with_quotes(node.type),
            wrap_string_with_quotes(node.model.identifier),
            wrap_string_with_quotes(dbt.escape_single_quotes(node.label)),
            wrap_string_with_quotes(node.sql),
            wrap_string_with_quotes(node.timestamp),
            wrap_string_with_quotes(node.package_name),
            wrap_string_with_quotes(node.dimensions|join(' - ')),
            metric_filters,
            wrap_string_with_quotes(node.meta | tojson)
            ]
          %}

        {%- do values.append(values_line) -%}

    {%- endfor -%}
    {%- endif -%}

    {{ return(values) }}

{%- endmacro -%}
