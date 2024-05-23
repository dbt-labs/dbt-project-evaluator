{% macro calculate_number_lines(node) %}
    {{ return(adapter.dispatch('calculate_number_lines', 'dbt_project_evaluator')(node)) }}
{% endmacro %}

{% macro default__calculate_number_lines(node) %}

    {% if node.resource_type == 'model' %}

        {% if execute %}
        {%- set model_raw_sql = node.raw_sql or node.raw_code -%}
        {%- else -%}
        {%- set model_raw_sql = '' -%}
        {%- endif -%}

        {{ return(model_raw_sql.count("\n")) + 1 }}

    {% endif %}

    {{ return(0) }}

{% endmacro %}
