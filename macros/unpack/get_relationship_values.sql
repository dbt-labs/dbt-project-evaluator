{%- macro get_relationship_values(node_type) -%}
    {{ return(adapter.dispatch('get_relationship_values', 'dbt_project_evaluator')(node_type)) }}
{%- endmacro -%}

{%- macro default__get_relationship_values(node_type) -%}

    {%- if execute -%}
        {%- if node_type == 'nodes' %}
            {% set nodes_list = graph.nodes.values() %}   
        {%- elif node_type == 'exposures' -%}
            {% set nodes_list = graph.exposures.values() %}
        {%- elif node_type == 'metrics' -%}
            {% set nodes_list = graph.metrics.values() %}
        {%- else -%}
            {{ exceptions.raise_compiler_error("node_type needs to be either nodes, exposures or metrics, got " ~ node_type) }}
        {% endif -%}
        
        {%- set values = [] -%}

        {%- for node in nodes_list -%}

            {%- if node.get('depends_on',{}).get('nodes',[]) |length == 0 -%}

                {%- set values_line = 
                  [
                    "cast('" ~ node.unique_id ~ "' as " ~ dbt_project_evaluator.type_string_dpe() ~ ")",
                    "cast(NULL as " ~ dbt_project_evaluator.type_string_dpe() ~ ")",
                    "FALSE",
                  ] 
                %}
                  
                {%- do values.append(values_line) -%}

            {%- else -%}       

                {%- for parent in node.get('depends_on',{}).get('nodes',[]) -%}

                    {%- set values_line = 
                        [
                            "cast('" ~ node.unique_id ~ "' as " ~ dbt_project_evaluator.type_string_dpe() ~ ")",
                            "cast('" ~ parent ~ "' as " ~ dbt_project_evaluator.type_string_dpe() ~ ")",
                            "" ~ loop.last ~ "" if node.unique_id.split('.')[0] == 'test' else "FALSE"
                        ]
                    %}
                      
                    {%- do values.append(values_line) -%}

                {%- endfor -%}

            {%- endif -%}

        {%- endfor -%}
    
    {{ return(values) }}

    {%- endif -%}
  
{%- endmacro -%}